# Stage 220: Models as a Service

Deploying a model is not the same as running a governed AI service. Without a
governance layer, teams create direct connections to individual model endpoints,
credentials scatter across namespaces, and usage becomes invisible — the
conditions that produce shadow AI in enterprise environments.

Models as a Service (MaaS) turns the serving infrastructure into a private
internal AI API. Developers and agents consume a single gateway URL with an
API key scoped to a subscription tier. The platform handles authentication,
per-model routing, token rate limiting, and usage tracking behind the scenes.
When a new model is added or a backend swaps from hosted to local inference, no
consumer configuration changes — MaaS governs what is available, who can use it,
and how much they can consume.

## Building Blocks

- **MaaS API** activated via DataScienceCluster, providing the Gen AI Studio
  interface in the RHOAI Dashboard for API key management, model browsing, and
  usage tracking
- **MaaS model registration** — three models registered as MaaS endpoints
  matching the LLMInferenceServices from stage 210 (`gpt-oss-120b`,
  `nemotron-nano-30b`, `nemotron-mini-4b`)
- **MaaS subscriptions** — two tiers (`standard` and `premium`) with
  Kuadrant AuthPolicies for per-tier rate limiting and authentication
- **MaaS database** (PostgreSQL) for API key storage and usage tracking,
  with automated key-cleanup maintenance
- **Dashboard flags** enabling the Gen AI Studio and MaaS pages in the
  RHOAI Dashboard
- **Monitoring** — PrometheusRules for vLLM serving health alerts

## Architecture

```text
OpenShift Cluster
├── MaaS Gateway (from Stage 210)
│   ├── AuthPolicies: standard-tier · premium-tier
│   └── External route: maas.<cluster-domain>
├── redhat-ods-applications
│   ├── MaaS API (Gen AI Studio backend)
│   ├── MaaS DB (PostgreSQL)
│   └── Dashboard flags (Gen AI Studio + MaaS pages enabled)
├── models-as-a-service namespace
│   ├── Model registrations: gpt-oss-120b · nemotron-nano-30b · nemotron-mini-4b
│   ├── Subscriptions: standard-tier · premium-tier
│   └── Monitoring: PrometheusRules for vLLM health
└── DSC Activation
    └── ModelsAsService: Managed
```

Agents and users interact with the MaaS gateway using API keys minted in the
Gen AI Studio. Each key is scoped to a subscription tier with rate limits
enforced by Kuadrant AuthPolicies.

## Official Documentation

- [Govern LLM access with Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/govern_llm_access_with_models-as-a-service/index)

## Prerequisites

- Stage 210 deployed and validated (KServe, gateway, and Kuadrant ready)
