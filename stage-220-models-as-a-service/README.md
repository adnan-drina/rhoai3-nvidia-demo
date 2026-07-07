# Stage 220: Models as a Service

## Why

Enterprise multi-agent workflows need governed model access with API key
management, usage tracking, rate limiting, and policy enforcement. MaaS
provides a gateway that decouples agent applications from individual model
endpoints.

## What

- **MaaS Gateway** for governed LLM access
- **Local model** registration through MaaS
- **External model** access (e.g., OpenAI GPT) through MaaS
- **API key management** for per-team/per-agent model access

## Architecture

```text
OpenShift Cluster
├── models-as-a-service namespace
│   ├── MaaS Gateway
│   ├── Local model (via Stage 210 endpoint)
│   └── External model (OpenAI/NVIDIA API)
└── Agent applications consume MaaS API
```

## Official Documentation

- [Govern LLM access with Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/govern_llm_access_with_models-as-a-service/index)

## Prerequisites

- Stage 210 deployed and validated (model endpoint available)
