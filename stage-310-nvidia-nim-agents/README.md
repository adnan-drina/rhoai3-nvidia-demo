# Stage 310: NVIDIA NIM Agents

## Why

Multi-agent research workflows benefit from specialized inference
microservices optimized for different tasks. NVIDIA NIM provides
production-ready, GPU-optimized containers for LLM inference, embedding,
and retrieval that serve as the computational backbone for agent workloads.

## What

- **NVIDIA NIM** microservices deployed on OpenShift with GPU scheduling
- **NGC pull credentials** for accessing NIM container images
- **NIM endpoints** registered through MaaS for governed agent access
- **Agent-optimized models** for reasoning, coding, and research tasks

## Architecture

```text
OpenShift Cluster
├── nvidia-nim-agents namespace
│   ├── NIM LLM Inference (reasoning model)
│   ├── NIM Embedding Service
│   └── NGC pull secrets
├── MaaS Gateway (Stage 220)
│   └── NIM models registered as MaaS endpoints
└── Kueue (Stage 120)
    └── GPU scheduling for NIM workloads
```

## Official Documentation

- [NVIDIA NIM](https://docs.nvidia.com/nim/)
- [NVIDIA NGC Catalog](https://catalog.ngc.nvidia.com/)
- [Deploying models on RHOAI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/deploying_models/index)

## Prerequisites

- Stage 220 deployed and validated (MaaS gateway available)
- NVIDIA API key configured in `.env`
