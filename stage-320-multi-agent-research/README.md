# Stage 320: Multi-Agent Research (NVIDIA AI-Q)

## Why

The demo's destination: an AI-Q research assistant (NVIDIA AI-Q Blueprint /
NeMo Agent Toolkit) that answers conversational questions, produces cited
shallow research, and runs asynchronous deep-research reports - with every
model call governed by the Models-as-a-Service platform built in Stages
110-310 (per-model gateway endpoints, persona-owned API key, tier limits).

Source: rh-ai-quickstart/rh-research @ `quickstart` (pinned 5751e85),
ported chart-to-Kustomize per the project No-Helm decision (PLAN.md).

## What

- Project `research-agents`: AI-Q backend + frontend + PostgreSQL job
  store; frontend Route; persona RBAC (admins=admin, demo users=edit).
- Model wiring (`aiq-model-wiring` ConfigMap, script-managed): orchestrator
  gpt-oss-120b, intent/researcher Nemotron Nano 30B, summary Nemotron Mini
  4B - hosted NVIDIA models through the MaaS gateway today; local LLMIS
  swap pairs documented for GPU arrival (docs/OPERATIONS.md runbook).
- Governance: `aiq-maas-key` minted by ai-researcher
  ("aiq-research-agent-demo-premium"); Tavily web search via
  `aiq-credentials`.
- Shortcuts: RHOAI dashboard tile + app-launcher ConsoleLink
  ("AI-Q Research Assistant").

## How (demo script, from the upstream verification guide)

1. Open the AI-Q tile / launcher entry, sign in as ai-researcher.
2. Conversational: "Hello" -> instant meta answer (intent model).
3. Shallow research: "What is Red Hat OpenShift?" -> cited answer in
   10-30s (researcher + Tavily through MaaS).
4. Deep research: "Provide a comprehensive analysis of Kubernetes
   security best practices" -> async structured report (2-5 min,
   orchestrator gpt-oss-120b).
5. Governance beat: show the key in Gen AI studio -> API keys and the
   per-model traffic in the Grafana LLM dashboards.

Deferred (docs/BACKLOG.md): MLflow tracing phase (DSC mlflow activation,
OBC artifact store, otel redaction config), researcher swap beat to
nemotron-super-120b.

## Verify

    ./stage-320-multi-agent-research/validate.sh   # includes /generate E2E
