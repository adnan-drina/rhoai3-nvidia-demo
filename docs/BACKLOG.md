# Backlog

Active backlog for the multi-agent research workflows demo.

## Documentation

- [ ] **Demo Walkthrough screenshots for stages 210-320** — stages 110 and
  120 have deployed-state screenshots in their Demo Walkthrough sections;
  stages 210, 220, 310, and 320 need equivalent screenshots captured from
  the live cluster (ArgoCD app detail, RHOAI Dashboard views, Gen AI Studio,
  AI-Q frontend, Grafana dashboards).

## Deferred

- **Agent evaluation stage (former Stage 330)** — removed from active scope
  (user decision, 2026-07-07) because the rh-research quickstart does not
  deploy evaluation: the AI-Q benchmarks (DeepResearch Bench, FreshQA via
  `nat eval`) are an upstream CLI/notebook developer workflow, and guardrails
  (NeMo Guardrails) are upstream-roadmap only. MLflow trace export moved into
  Stage 320 scope since it ships in the quickstart app chart itself. A future
  evaluation stage would cover: `nat eval` benchmark runs against the deployed
  workflow, evaluation dashboards, the rh-research observability stack
  (Cluster Observability Operator, Grafana vLLM/GPU dashboards, OTel
  collector), and a guardrails approach (RHOAI TrustyAI guardrails or NeMo
  Guardrails once upstream integrates it).

- **Stage 320 phase B: MLflow tracing** — DSC mlflowoperator activation, OBC
  artifact store, aiq otel tracing block + token secret/RBAC port, redaction
  on. Acceptance criterion deferred from the initial port.

- **On-cluster NIM microservices** — NVIDIA RAG Blueprint FRAG knowledge
  layer via local NIM containers (see stage-310 PLAN.md deferred section;
  needs GPU capacity beyond the 2x p5.4xlarge layout).

- **Distributed tracing for agents** — Tempo + OpenTelemetry collector +
  distributed-tracing UIPlugin; DSCI monitoring.traces. Relevant for
  stage 320 agent debugging (rhoai3-demo stage-240 pattern).

- **Stage 320 storage wiring** — MLflow artifact-store OBC (+ Tempo S3 OBC
  when tracing is ported) against openshift-storage.noobaa.io StorageClass.

## Future Considerations

- RHOAI 3.5 upgrade follow-ups (RHOAIENG-63297 fixed in 3.5 MaaS API):
  re-test the native MaaS playground flow for hosted NVIDIA models; if
  namespaced targetModel IDs work, delete the four custom-endpoint
  playground entries and their Secrets (demo-sandbox) and simplify the
  asset page back to catalog rows only.
- MCP servers for the AI asset endpoints MCP tab (rhoai3-demo mcp/base).
- Advanced agent memory and context management.
- Cross-cluster agent federation.
- Agent workflow versioning and rollback.
