# Stage 320: Multi-Agent Research Workflows

## Why

Complex research tasks — literature review, data analysis, hypothesis
generation, experimental design — benefit from coordinated teams of specialized
AI agents. A multi-agent orchestration layer enables enterprises to compose
governed, observable research workflows that combine the strengths of multiple
models and tools.

## What

- **Agent orchestration framework** for composing multi-agent research workflows
- **Specialized research agents** (researcher, analyst, synthesizer, reviewer)
- **Agent-to-agent communication** through governed MaaS endpoints
- **Research workflow definitions** as declarative configurations
- **OpenTelemetry tracing** for end-to-end workflow observability

## Architecture

```text
OpenShift Cluster
├── multi-agent-research namespace
│   ├── Orchestrator Agent
│   │   ├── Research Agent → NIM/MaaS endpoints
│   │   ├── Analysis Agent → NIM/MaaS endpoints
│   │   ├── Synthesis Agent → NIM/MaaS endpoints
│   │   └── Review Agent → NIM/MaaS + Guardrails
│   ├── Workflow Configuration (ConfigMaps)
│   └── OTel Collector → Tracing backend
├── MaaS Gateway (Stage 220)
└── NIM Endpoints (Stage 310)
```

## Official Documentation

- [Working with Llama Stack](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_llama_stack)
- [NVIDIA NIM Agent Blueprints](https://docs.nvidia.com/nim/)

## Prerequisites

- Stage 310 deployed and validated (NIM endpoints available)
