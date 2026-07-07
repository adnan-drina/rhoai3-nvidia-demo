---
name: nvidia
skill-group: NVIDIA Integration
skill-prefix: nvidia-
applies-to:
  - docs/PLATFORM_BASELINE.md
  - docs/**/*.md
  - gitops/**
  - stage-3*/**
  - .agents/skills/nvidia-*/**
---

# NVIDIA Integration

Use the `nvidia-*` skills as the source of truth for NVIDIA technology
integration including NIM microservices, NeMo Guardrails, and agent
frameworks:

- `.agents/skills/nvidia-nim-overview/SKILL.md`
- `.agents/skills/nvidia-agent-workflows/SKILL.md`
- `.agents/skills/nvidia-nemo-guardrails/SKILL.md`

## Source Rules

- NVIDIA official documentation is the authority for NIM container images,
  API specifications, model support matrices, and deployment configurations.
- Red Hat OpenShift AI documentation remains the authority for RHOAI-managed
  components that integrate with NVIDIA technologies (GPU Operator, KServe,
  hardware profiles).
- Do not invent NIM API endpoints, container image tags, or model identifiers.
  Verify against NVIDIA NGC catalog or official NIM documentation.

## Multi-Agent Research Workflow Guidance

- Agent workflows should use governed MaaS model endpoints where available
  rather than direct model-serving connections.
- Agent orchestration patterns should be observable through OpenTelemetry
  tracing and evaluable through the agent evaluation framework.
- Keep agent framework configuration in Git-managed ConfigMaps and Secrets
  created by deploy scripts. Do not embed API keys or model endpoints in
  application code.
- NVIDIA NIM microservices deployed on OpenShift should follow the same
  GitOps patterns as other RHOAI workloads: Kustomize manifests, ArgoCD
  Applications, and deploy/validate scripts.

## Integration Points with RHOAI

- GPU scheduling: NVIDIA GPU Operator + Kueue hardware profiles from Stage 120
- Model serving: KServe/vLLM runtime from Stage 210, NIM containers for
  specialized agent models
- Model governance: MaaS gateway from Stage 220 for governed agent model access
- Guardrails: NeMo Guardrails for agent safety and compliance
- Observability: OpenTelemetry for agent workflow tracing
