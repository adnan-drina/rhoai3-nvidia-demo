# Stage 210: Model Serving Foundation

## Why

Multi-agent research workflows need reliable, high-performance model endpoints.
KServe with vLLM provides GPU-optimized inference with OpenAI-compatible APIs
that agents can consume as tools.

## What

- **KServe** model serving platform enabled via DataScienceCluster
- **vLLM** runtime for GPU-accelerated LLM inference
- **Model endpoint** for the primary research workflow model
- **Monitoring** with Grafana dashboards for inference metrics

## Architecture

```text
OpenShift Cluster
├── demo-sandbox namespace
│   ├── KServe InferenceService (vLLM runtime)
│   └── Model endpoint (OpenAI-compatible API)
└── Monitoring
    └── Grafana dashboards
```

## Official Documentation

- [Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index)
- [Configuring your model-serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/configuring_your_model-serving_platform)

## Prerequisites

- Stage 120 deployed and validated (GPU available)
