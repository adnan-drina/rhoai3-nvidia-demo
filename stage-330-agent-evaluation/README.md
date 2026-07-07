# Stage 330: Agent Evaluation

## Why

Enterprise AI agents need systematic evaluation to ensure quality, safety,
and reliability. Agent evaluation goes beyond traditional model evaluation by
assessing multi-step reasoning, tool usage, inter-agent coordination, and
end-to-end workflow outcomes.

## What

- **Agent evaluation framework** for assessing multi-agent workflow quality
- **NeMo Guardrails** for agent safety and compliance enforcement
- **Evaluation metrics** for agent reasoning, accuracy, and collaboration
- **OpenTelemetry observability** for agent workflow tracing and debugging
- **Evaluation dashboards** for visual analysis of agent performance

## Architecture

```text
OpenShift Cluster
├── agent-evaluation namespace
│   ├── Evaluation Framework
│   │   ├── Workflow quality metrics
│   │   ├── Agent reasoning evaluation
│   │   └── Safety compliance checks
│   ├── NeMo Guardrails Service
│   │   └── Agent interaction policies
│   └── Observability
│       ├── OTel Collector
│       ├── Tempo (trace storage)
│       └── Evaluation Dashboards
├── Multi-Agent Workflows (Stage 320)
└── MaaS Gateway (Stage 220)
```

## Official Documentation

- [Evaluating AI systems](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/evaluating_ai_systems/index)
- [Ensuring AI safety with guardrails](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/enabling_ai_safety_with_guardrails/index)
- [NeMo Guardrails](https://docs.nvidia.com/nemo/guardrails/)

## Prerequisites

- Stage 320 deployed and validated (multi-agent workflows running)
