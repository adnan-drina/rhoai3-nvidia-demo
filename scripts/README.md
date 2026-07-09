# Scripts

Shared project automation. Stage-specific deploy and validate scripts live in
each `stage-YXX-slug/` directory.

## Shared Scripts

| Script | Purpose |
|--------|---------|
| `validate-agent-guidance.rb` | Validates `.agents/` skill frontmatter, rule references, and inventory |

## Stage Scripts

Each stage provides a `deploy.sh` and `validate.sh`:

| Stage | deploy.sh | validate.sh |
|-------|-----------|-------------|
| [110 — RHOAI Base Platform](../stage-110-rhoai-base-platform/) | Bootstraps ArgoCD, creates the stage Application | Checks operators, DSC, MCG, Model Registry |
| [120 — GPU as a Service](../stage-120-gpu-as-a-service/) | Generates GPU MachineSets, creates the stage Application | Checks NFD, GPU Operator, Kueue, hardware profiles |
| [210 — Model Serving Foundation](../stage-210-model-serving-foundation/) | Creates the stage Application, waits for KServe and Kuadrant | Checks gateway, Grafana, LLMInferenceServices |
| [220 — Models as a Service](../stage-220-models-as-a-service/) | Creates MaaS DB secrets, creates the stage Application | Checks MaaS API, model registrations, subscriptions |
| [310 — NVIDIA NIM Agents](../stage-310-nvidia-nim-agents/) | Creates NVIDIA API secret, creates the stage Application | Checks ExternalModels, governed E2E inference |
| [320 — Multi-Agent Research](../stage-320-multi-agent-research/) | Creates secrets and model wiring, creates the stage Application | Checks AI-Q backend, frontend, E2E /generate |

Stage 110 also includes `setup-access.sh` for creating demo user accounts
(`ai-admin`, `ai-developer`, `ai-researcher`) via htpasswd.
