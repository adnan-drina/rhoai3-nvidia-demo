# RHOAI NVIDIA Demo - Codex Instructions

Demo of building Multi-Agent Research Workflows for enterprise generative AI
using Red Hat OpenShift AI and NVIDIA technologies on the product baseline in
`docs/PLATFORM_BASELINE.md`.

## Documentation First

- Official Red Hat docs for the active `docs/PLATFORM_BASELINE.md` versions are
  the source of truth.
- NVIDIA documentation for NIM, NeMo, and agent frameworks supplements Red Hat
  product docs for NVIDIA-specific integration points.
- Do not invent CR fields, API versions, annotations, or operator
  configurations.
- If unsure, propose a verification command (`oc explain`, `oc get crd`) or
  consult the official docs index in `docs/PLATFORM_BASELINE.md`.

## Active Implementation State

The implementation is being built stage by stage.

Active stages:

```text
stage-110-rhoai-base-platform/    # GitOps bootstrap, ODF MCG, RHOAI base
stage-120-gpu-as-a-service/       # GPU node, NFD, NVIDIA GPU Operator, Kueue, hardware profiles
stage-210-model-serving-foundation/ # KServe model serving foundation via shared Stage 110 DSC owner
stage-220-models-as-a-service/    # MaaS governance, local and external model access
stage-310-nvidia-nim-agents/      # NVIDIA NIM microservices for agentic AI workloads
stage-320-multi-agent-research/   # Multi-agent research workflow orchestration
stage-330-agent-evaluation/       # Agent workflow evaluation and observability
gitops/                            # Active GitOps source tree
scripts/                           # Shared project automation
docs/                              # Active project docs and product baseline
.agents/                           # Shared skills, rules, reference maps, and hooks
```

## GitOps Constraints

- ArgoCD `resourceTrackingMethod` MUST be `annotation` (not `label`).
- All demo Applications should use `project: rhoai-nvidia-demo` unless the
  implementation explicitly changes the project model.
- ArgoCD cluster-admin remains acceptable for this demo only when documented in
  `docs/OPERATIONS.md`.
- Operator-managed operand images MUST remain owned by OLM and the product
  operator. Do not patch generated operand image fields, generated CSV content,
  or operator-created operand Deployments as a compatibility shortcut unless
  official product documentation exposes that field as a supported override and
  the relevant skill records the exception.
- Compatibility fixes for generated operands should use Git-managed
  Subscription lifecycle policy (`channel`, `startingCSV`,
  `installPlanApproval`), product baseline alignment, or a product-controller
  fix. Live pod deletion to recover from controller crash loops is operational
  recovery only, not desired GitOps state.
- New deploy automation must apply ArgoCD Applications first and avoid direct
  `oc apply -k` against ArgoCD-managed resources.

## OpenShift Safety Guard

- Open this repository as its own Codex project; do not open
  `/Users/adrina/Sandbox` as the active project for live cluster work.
- Before running live `oc`/`kubectl` commands, verify the target cluster against
  the repo-local environment guard.
- Set `RHOAI_EXPECTED_API_SERVER` in the local `.env` to a unique target
  API-server substring before deploy, validate, bootstrap, or
  resource-management scripts run.
- If using a project-local kubeconfig, set `KUBECONFIG` in `.env` to an
  absolute path under `tmp/`; never commit kubeconfig files.
- Do not bypass the guard with `RHOAI_ALLOW_UNGUARDED_CLUSTER=true` unless the
  user explicitly confirms the current cluster and the command is low risk.
- Do not read credentials from another project by default.
- New scripts that touch a live cluster must include the guard behavior before
  they are considered active.

## Code And Docs Must Be Aligned

Every new capability should be introduced as an atomic stage: documentation,
GitOps artifacts, scripts, and validation.

Stage READMEs should provide the Why and What for a technical audience:
concept value, RHOAI technology mapping, and architecture delta. GitOps and
live demos show the How. Put operational details in `docs/OPERATIONS.md` and
failure recovery in `docs/TROUBLESHOOTING.md`.

Do not claim capabilities that are not implemented. Future or deferred
capabilities must be clearly labeled.

Do not silently defer or remove components that are part of an agreed stage
scope, source pattern, or acceptance contract. Before moving such a component
to `deferred`, `future`, `non-goal`, or backlog status, discuss it with the
user, capture the user's explicit acceptance, and record the decision in the
stage `PLAN.md` or `docs/BACKLOG.md`.

## Self-Signed Certs

Use `--insecure-skip-tls-verify=true` (oc) and `-k` (curl) freely. Do not
implement production PKI for this demo.

## Branching And Commits

GitHub Flow + Trunk-Based Development. `main` is the stable trunk for released
demo content. During active refactoring, ArgoCD Applications may temporarily
pin to the active refactoring branch; update the Application `targetRevision`
back to the intended release ref when stabilizing.

Commit format: `type(scope): description` - types: feat, fix, docs, refactor,
chore, ci. Scope: stage identifier or slug for stage-specific changes,
component name for cross-cutting changes.

## Detailed Rules

For project structure, GitOps authoring, documentation, manifest review, Red
Hat source alignment, and shared agent guidance, read `.agents/rules/project.md`.

For live demo environment deployment, validation, troubleshooting, shutdown,
recovery, and redeploy, read `.agents/rules/env.md`.

For RHOAI platform component guidance, read `.agents/rules/rhoai.md`.

For OpenShift Container Platform infrastructure, control plane, networking,
authentication, monitoring, GitOps, cluster, and storage integration guidance,
read `.agents/rules/ocp.md`.

For OpenShift Data Foundation storage, object storage, NooBaa, and ODF storage
classes, read `.agents/rules/odf.md`.

For NVIDIA integration, NIM microservices, NeMo frameworks, and agent workflow
guidance, read `.agents/rules/nvidia.md`.

For visual assets, architecture diagrams, decks, and presentation outputs, read
`.agents/rules/assets.md`.

## Shared Skills

Canonical skills live in `.agents/skills/`, the Codex repo-skill discovery
path. Short tool-neutral rules live in `.agents/rules/`. Do not maintain
tool-specific skill discovery folders in this repo. Use the prefix plus
`metadata.skill-group` taxonomy for skill review:

| Group | Prefix | Skills | Purpose |
|-------|--------|--------|---------|
| Project Structure | `project-*` | `project-structure`, `project-agent-guidance`, `project-demo-stage-authoring`, `project-gitops-authoring`, `project-documentation-authoring`, `project-manifest-review` | Repo layout, demo stage lifecycle, GitOps stage conventions, documentation structure, manifest review, and shared AI guidance |
| Demo Environment | `env-*` | `env-deploy-and-evaluate`, `env-troubleshoot`, `env-manage-resources` | Live AWS/OpenShift demo deployment, validation, troubleshooting, shutdown, recovery, and redeploy |
| RHOAI Platform | `rhoai-*` | Component skills planned per stage implementation | Official-doc-backed active-baseline RHOAI component installation, configuration, and usage |
| OpenShift Platform | `ocp-*` | Component skills planned per stage implementation | Official-doc-backed OpenShift Container Platform guidance |
| OpenShift Data Foundation | `odf-*` | Component skills planned per stage implementation | Official-doc-backed OpenShift Data Foundation storage guidance |
| NVIDIA Integration | `nvidia-*` | `nvidia-nim-overview`, `nvidia-agent-workflows`, `nvidia-nemo-guardrails` | NVIDIA NIM, NeMo, and agent framework integration guidance |
| Assets & Miscellaneous | `assets-*` | `assets-red-hat-quick-deck` | Visual, deck, and presentation assets |

Use `.agents/skills/project-agent-guidance/SKILL.md` for the full governance
model.

## Subagents

No shared subagents are currently tracked. Add tool-specific subagents only for
genuinely tool-specific context isolation needs; shared workflows belong in
`.agents/skills/`.
