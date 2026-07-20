# Stage 320: Multi-Agent Research

Enterprise AI is progressing from single-model chatbots through
retrieval-augmented generation to multi-agent systems where specialized models
collaborate on complex tasks. This stage is the demo's destination — an AI-Q
Research Assistant that answers conversational questions, produces cited shallow
research, and runs asynchronous deep-research reports using the NVIDIA AI-Q
Blueprint.

Every model call flows through the Models-as-a-Service gateway built in stages
110-310. The research assistant authenticates with its own API key, scoped to a
subscription tier with per-model rate limits and usage tracking. This proves
every governance layer works end to end: GitOps-managed infrastructure, GPU
scheduling, model serving, gateway authentication, and consumption metering —
all visible and auditable from a single platform.

## Building Blocks

- **AI-Q Backend** — NVIDIA AI-Q Blueprint (NeMo Agent Toolkit) research
  service with three workflow modes:
  - *Conversational* — instant meta answers via the intent model
  - *Shallow research* — cited answers in 10-30 seconds using the researcher
    model + Tavily web search through MaaS
  - *Deep research* — asynchronous structured reports (2-5 minutes) using the
    orchestrator model with multi-step reasoning
- **AI-Q Frontend** — web interface for research interactions, accessible via
  OpenShift Route
- **PostgreSQL job store** — persistent storage for async deep-research tasks
- **Model wiring** (`aiq-model-wiring` ConfigMap) — maps each agent role to a
  MaaS gateway endpoint:
  - Orchestrator: `gpt-oss-120b` (hosted or local)
  - Researcher + Intent: `nemotron-nano-30b` (hosted or local)
  - Summary: `nemotron-mini-4b` (hosted or local)
- **MaaS API key** minted by `ai-researcher` persona under the `demo-premium`
  subscription — the research app authenticates to the gateway with its own
  governed key
- **Tavily web search** credentials for real-time research queries
- **RHOAI integration** — dashboard tile and app-launcher ConsoleLink for
  one-click access to the research assistant
- **Persona RBAC** — admins get admin access, demo users get edit access to
  the `research-agents` project

## Architecture

```text
OpenShift Cluster
├── research-agents namespace
│   ├── AI-Q Backend (NeMo Agent Toolkit)
│   │   ├── Intent classification  → nemotron-nano-30b via MaaS
│   │   ├── Shallow research       → nemotron-nano-30b + Tavily via MaaS
│   │   └── Deep research          → gpt-oss-120b (orchestrator) via MaaS
│   ├── AI-Q Frontend (web UI) + Route
│   ├── PostgreSQL (async job store)
│   ├── Secrets: aiq-credentials · aiq-maas-key
│   └── ConfigMap: aiq-model-wiring
├── MaaS Gateway (Stages 210-310)
│   └── Governed model access (API key auth, rate limits, usage tracking)
├── RHOAI Dashboard
│   └── AI-Q tile + app-launcher ConsoleLink
└── Models (Stages 210 + 310)
    ├── Hosted: NVIDIA API Catalog endpoints (active today)
    └── Local: LLMInferenceServices (activate with GPU nodes)
```

Model wiring is script-managed: `deploy.sh` creates the ConfigMap pointing
at hosted NVIDIA models through MaaS. When GPU nodes arrive, the model URLs
swap to local LLMInferenceService endpoints with one ConfigMap update — see
the GPU Arrival Day Runbook in `docs/OPERATIONS.md`.

## Official Documentation

- [NVIDIA AI-Q Blueprint](https://docs.nvidia.com/ai-q/)
- [NVIDIA NeMo Agent Toolkit](https://docs.nvidia.com/nemo/agent-toolkit/)
- [Govern LLM access with Models-as-a-Service](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html-single/govern_llm_access_with_models-as-a-service/index)

## Prerequisites

- Stage 310 deployed and validated (MaaS with hosted NVIDIA models)
- `TAVILY_API_KEY` configured in `.env`
- `AI_RESEARCHER_PASSWORD` configured in `.env` (for MaaS API key minting)
