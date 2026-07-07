# Operations

This document will contain the active operating model, deployment order,
validation strategy, and day-2 operational notes once stages are implemented.

## Deployment Order

Stages must be deployed in numerical order:

1. Stage 110 - RHOAI Base Platform (GitOps bootstrap, ODF, RHOAI operator)
2. Stage 120 - GPU as a Service (GPU worker, NFD, GPU Operator, Kueue)
3. Stage 210 - Model Serving Foundation (KServe, model endpoint)
4. Stage 220 - Models as a Service (MaaS governance)
5. Stage 310 - NVIDIA NIM Agents (NIM microservices)
6. Stage 320 - Multi-Agent Research (agent orchestration)
7. Stage 330 - Agent Evaluation (evaluation and observability)

## Validation Strategy

Each stage provides a `validate.sh` script that checks component health.
Run validation after each stage deployment before proceeding to the next.

## Day-2 Operations

_To be documented as stages are implemented._
