# Stage 210: Model Serving Foundation

## Why

Multi-agent research workflows need reliable, high-performance model endpoints
with authentication, observability, and gateway-level routing. This stage
builds the full serving infrastructure — KServe for model lifecycle, Gateway API
for unified ingress, Kuadrant for authentication and rate limiting, and Grafana
for inference dashboards — so that stages 220-320 can focus on governance and
agent logic rather than plumbing.

## What

- **KServe** model serving platform enabled via DataScienceCluster activation
  hook — provides the `LLMInferenceService` CRD for declarative model
  lifecycle with vLLM runtime
- **LLMInferenceServices** for three models: `gpt-oss-120b` (orchestrator),
  `nemotron-nano-30b` (researcher), and `nemotron-mini-4b` (intent/summary) —
  model pods start when GPU nodes are available
- **Red Hat Connectivity Link** (Kuadrant) with Authorino for gateway-level
  AuthN/AuthZ and Limitador for rate limiting
- **MaaS Gateway** (Gateway API) in `openshift-ingress` — unified HTTPS
  entrypoint for all model endpoints, with TLS and Authorino trust
- **Leader Worker Set** (LWS) operator for multi-pod model serving topologies
- **cert-manager** operator for automated TLS certificate management
- **Grafana Operator** with OAuth proxy, OpenShift monitoring datasource,
  vLLM/KServe GPU dashboard, LLM performance dashboard, console link, and
  RHOAI dashboard tile

## Architecture

```text
OpenShift Cluster
├── models-as-a-service namespace
│   ├── LLMInferenceService: gpt-oss-120b         (orchestrator)
│   ├── LLMInferenceService: nemotron-nano-30b     (researcher)
│   └── LLMInferenceService: nemotron-mini-4b      (intent/summary)
├── openshift-ingress
│   └── MaaS Gateway (Gateway API + Authorino TLS)
├── kuadrant-system
│   └── Kuadrant instance (Authorino + Limitador)
├── rhoai-demo-grafana
│   ├── Grafana with OAuth proxy
│   ├── OpenShift monitoring datasource
│   └── Dashboards: vLLM/KServe GPU · LLM Performance
├── DSC Activation
│   └── KServe: Managed (hook Job patches DataScienceCluster)
└── Operators
    ├── cert-manager
    ├── Red Hat Connectivity Link (Kuadrant)
    └── Leader Worker Set
```

`deploy.sh` creates the ArgoCD Application and waits for operator CSVs,
Kuadrant readiness, gateway programming, and DSC KServe activation. The
three LLMInferenceService CRs are created by ArgoCD; their model pods start
automatically when GPU nodes join the cluster.

## Official Documentation

- [Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index)
- [Configuring your model-serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/configuring_your_model-serving_platform)
- [Red Hat Connectivity Link](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.3)

## Prerequisites

- Stage 120 deployed and validated
