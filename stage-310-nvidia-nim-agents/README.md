# Stage 310: NVIDIA NIM Agents

## Why

Multi-agent research workflows need frontier models for orchestration,
reasoning, and summarization. The
[Red Hat AI Factory with NVIDIA](https://www.redhat.com/en/products/ai/factory-with-nvidia)
brings NVIDIA Nemotron and GPT-OSS models into the governed Red Hat AI platform
through both hosted API endpoints and downloadable NIM containers for local
GPU-accelerated inference.

This stage registers hosted NVIDIA models as governed MaaS endpoints so that
agent applications consume them through the same gateway, API keys, and rate
limits as locally-served models. The hosted-to-local swap is the key hybrid
deployment pattern: teams can start building agents immediately against hosted
endpoints, then move inference onto private infrastructure when GPU capacity
arrives — without changing a single line of application code.

## What

- **Hosted NVIDIA models** registered as `ExternalModel` resources through the
  MaaS gateway — `gpt-oss-120b`, `nemotron-super-120b`, `nemotron-nano-30b`,
  and `nemotron-mini-4b` via `integrate.api.nvidia.com`
- **NVIDIA API credentials** secret for hosted NIM access, labeled for
  gateway-level credential injection
- **MaaS subscriptions** — two tiers with per-model token rate limits:
  - `demo-standard`: research and summarization models
  - `demo-premium`: orchestrator and frontier models
- **Kuadrant AuthPolicies** per tier for gateway-enforced authentication
  and rate limiting

When GPU nodes are available, the local `LLMInferenceService` endpoints from
stage 210 serve the same model names. Agents see no difference — the MaaS
gateway routes to whichever backend is live.

## Architecture

```text
OpenShift Cluster
├── models-as-a-service namespace
│   ├── ExternalModel: gpt-oss-120b-hosted      → integrate.api.nvidia.com
│   ├── ExternalModel: nemotron-super-120b-hosted
│   ├── ExternalModel: nemotron-nano-30b-hosted
│   ├── ExternalModel: nemotron-mini-4b-hosted
│   ├── MaaSSubscription: demo-standard (research models, rate-limited)
│   ├── MaaSSubscription: demo-premium  (orchestrator + frontier models)
│   ├── AuthPolicy: standard-tier
│   ├── AuthPolicy: premium-tier
│   └── Secret: nvidia-api-credentials
├── MaaS Gateway (Stage 210)
│   └── Routes to hosted or local backends per model name
└── Local LLMInferenceServices (Stage 210, GPU-dependent)
    └── Same model names — agents swap transparently
```

## Official Documentation

- [NVIDIA NIM](https://docs.nvidia.com/nim/)
- [NVIDIA API Catalog](https://build.nvidia.com/)
- [Govern LLM access with Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/govern_llm_access_with_models-as-a-service/index)

## Prerequisites

- Stage 220 deployed and validated (MaaS gateway and API ready)
- `NVIDIA_API_KEY` configured in `.env`
