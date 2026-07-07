# Multi-Agent Research Workflows with Red Hat AI and NVIDIA

This repository implements a staged Red Hat OpenShift AI demo showcasing
multi-agent research workflows powered by NVIDIA technologies on a private
enterprise AI platform.

## Demo Story

Enterprise research teams need governed, observable, and repeatable AI agent
workflows that coordinate multiple specialized models to solve complex research
tasks. This demo builds that capability layer by layer on Red Hat OpenShift AI,
using NVIDIA NIM microservices and agent frameworks for the agentic AI tier.

## Active Stages

### Platform Foundation (100s)

- `stage-110-rhoai-base-platform/` - GitOps bootstrap, ODF MCG, RHOAI base platform, model registry
- `stage-120-gpu-as-a-service/` - GPU worker, NFD, NVIDIA GPU Operator, Kueue, hardware profiles

### Production GenAI (200s)

- `stage-210-model-serving-foundation/` - KServe/vLLM foundation, model endpoint, monitoring
- `stage-220-models-as-a-service/` - MaaS governance for local and external models

### Agentic AI & Multi-Agent Research (300s)

- `stage-310-nvidia-nim-agents/` - NVIDIA NIM microservices for agentic AI workloads
- `stage-320-multi-agent-research/` - Multi-agent research workflow orchestration
- `stage-330-agent-evaluation/` - Agent workflow evaluation and observability

## Project Structure

- `gitops/` - Active GitOps source tree (Kustomize + ArgoCD)
- `scripts/` - Shared project automation
- `.agents/` and `AGENTS.md` - Shared agent guidance
- `docs/PLATFORM_BASELINE.md` - Active product baseline and official docs index

## Getting Started

```bash
cp env.example .env
# Set RHOAI_EXPECTED_API_SERVER to your cluster API URL substring
# Set KUBECONFIG if using a project-local kubeconfig
```

See each stage README for deployment instructions.
