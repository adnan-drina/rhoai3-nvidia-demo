# Multi-Agent Research Workflows with Red Hat AI and NVIDIA

Enterprise research teams need governed, observable, and repeatable AI agent
workflows that coordinate multiple specialized models to solve complex research
tasks. This demo builds that capability layer by layer on
**Red Hat OpenShift AI 3.4** and **OpenShift 4.20**, using NVIDIA NIM
microservices and agent frameworks for the agentic AI tier.

The result is an **AI-Q Research Assistant** — a multi-agent system that answers
conversational questions, produces cited shallow research, and runs asynchronous
deep-research reports — with every model call governed by a Models-as-a-Service
gateway.

## Demo Stages

The demo is built in six incremental stages. Each stage adds a capability layer
and can be deployed independently on top of its prerequisites.

### Platform Foundation

| Stage | What it delivers |
|-------|------------------|
| [Stage 110 — RHOAI Base Platform](stage-110-rhoai-base-platform/) | GitOps bootstrap, ODF MCG object storage, RHOAI operator and DataScienceCluster, Model Registry |
| [Stage 120 — GPU as a Service](stage-120-gpu-as-a-service/) | GPU worker nodes, NFD, NVIDIA GPU Operator with MIG, Kueue scheduling, hardware profiles |

### Production GenAI

| Stage | What it delivers |
|-------|------------------|
| [Stage 210 — Model Serving Foundation](stage-210-model-serving-foundation/) | KServe serving platform, vLLM runtime, Grafana inference dashboards |
| [Stage 220 — Models as a Service](stage-220-models-as-a-service/) | MaaS gateway for governed LLM access, local and external model routing, API key management |

### Agentic AI and Multi-Agent Research

| Stage | What it delivers |
|-------|------------------|
| [Stage 310 — NVIDIA NIM Agents](stage-310-nvidia-nim-agents/) | NVIDIA NIM microservices for LLM inference, registered through MaaS |
| [Stage 320 — Multi-Agent Research](stage-320-multi-agent-research/) | AI-Q research assistant with conversational, shallow-research, and deep-research workflows |

## Architecture Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│  AI-Q Research Assistant (Stage 320)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Conversation │  │   Shallow   │  │   Deep Research         │ │
│  │   (intent)   │  │  Research   │  │  (orchestrator + tools) │ │
│  └──────┬───────┘  └──────┬──────┘  └────────────┬────────────┘ │
├─────────┴─────────────────┴──────────────────────┴──────────────┤
│  Models as a Service Gateway (Stage 220)                        │
│  API keys · rate limits · per-model routing · usage tracking    │
├─────────────────────────────────────────────────────────────────┤
│  Model Serving (Stages 210 + 310)                               │
│  KServe/vLLM local endpoints  ·  NVIDIA NIM microservices       │
├─────────────────────────────────────────────────────────────────┤
│  GPU as a Service (Stage 120)                                   │
│  H100 full + MIG partitioning · Kueue quotas · hardware profiles│
├─────────────────────────────────────────────────────────────────┤
│  RHOAI Base Platform (Stage 110)                                │
│  ArgoCD GitOps · ODF MCG · RHOAI operator · Model Registry      │
├─────────────────────────────────────────────────────────────────┤
│  OpenShift Container Platform 4.20                              │
└─────────────────────────────────────────────────────────────────┘
```

## Project Layout

```text
stage-YXX-slug/          Stage docs, deploy.sh, validate.sh
gitops/stage-YXX-slug/   Kustomize manifests synced by ArgoCD
scripts/                 Shared project automation
docs/                    Platform baseline, operations, troubleshooting, backlog
```

Each stage lives in two places: a **stage directory** with human docs and
scripts, and a **gitops directory** with Kustomize manifests that ArgoCD syncs
to the cluster. See [gitops/README.md](gitops/README.md) for conventions.

## Getting Started

```bash
cp env.example .env
# Edit .env:
#   RHOAI_EXPECTED_API_SERVER — unique substring of your cluster API URL
#   KUBECONFIG               — path to your kubeconfig (optional, under tmp/)
#   NVIDIA_API_KEY            — for NIM and hosted model access
```

Deploy stages in order. Each stage README explains what it delivers and why:

```bash
./stage-110-rhoai-base-platform/deploy.sh
./stage-110-rhoai-base-platform/validate.sh

./stage-120-gpu-as-a-service/deploy.sh
./stage-120-gpu-as-a-service/validate.sh

# ... continue through stages 210, 220, 310, 320
```

## Platform Baseline

| Component | Version |
|-----------|---------|
| Red Hat OpenShift AI Self-Managed | 3.4 |
| Red Hat OpenShift Container Platform | 4.20 |
| Red Hat OpenShift Data Foundation | 4.20 |
| NVIDIA GPU Operator | v26.3 |
| Red Hat build of Kueue | 1.3 |

See [docs/PLATFORM_BASELINE.md](docs/PLATFORM_BASELINE.md) for the full
baseline, version-match rules, and official documentation index.

## Documentation

| Document | Purpose |
|----------|---------|
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | Deployment order, day-2 operations, GPU arrival runbook |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Symptom-based diagnostics and recovery |
| [docs/BACKLOG.md](docs/BACKLOG.md) | Active backlog and deferred items |
| [docs/PLATFORM_BASELINE.md](docs/PLATFORM_BASELINE.md) | Product baseline and official docs index |
