# Backlog

Active backlog for the multi-agent research workflows demo implementation.

## Active Work

- [ ] Stage 110 - RHOAI Base Platform implementation
- [ ] Stage 120 - GPU as a Service implementation
- [ ] Stage 210 - Model Serving Foundation implementation
- [ ] Stage 220 - Models as a Service implementation
- [ ] Stage 310 - NVIDIA NIM Agents implementation
- [ ] Stage 320 - Multi-Agent Research Workflows implementation

## Future Work

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

## Future Considerations

- Advanced agent memory and context management
- Cross-cluster agent federation
- Agent workflow versioning and rollback
- Production-grade agent monitoring dashboards
- On-cluster NIM microservices via the NVIDIA RAG Blueprint FRAG knowledge
  layer (see stage-310 PLAN.md deferred section; needs GPU capacity beyond
  the 2x p5.4xlarge layout)

## Observability follow-ups (identified 2026-07-08, aligned with reference projects)

- Port the proven Grafana model-serving stack from rhoai3-demo /
  rhoai3-coding-demo stage-210/030 (Grafana operator + instance,
  openshift-monitoring datasource + cluster-monitoring-view RBAC, vLLM
  KServe/GPU + LLM performance dashboards, console link). This is the
  references' primary Observe & monitor implementation; ours currently
  covers the RHOAI-native path (COO + DSCI metrics + Perses dashboard).
- Distributed tracing for agents (rhoai3-demo stage-240 pattern): Tempo +
  OpenTelemetry collector + distributed-tracing UIPlugin; DSCI
  monitoring.traces. Relevant for stage 320 agent debugging.
- MCP servers for the AI asset endpoints MCP tab (rhoai3-demo mcp/base).
- Stage 320 storage wiring: MLflow artifact-store OBC (+ Tempo S3 OBC when
  tracing is ported) against openshift-storage.noobaa.io StorageClass.
- RHOAI 3.5 upgrade follow-ups (RHOAIENG-63297 fixed in 3.5 MaaS API):
  re-test the native MaaS playground flow for hosted NVIDIA models; if
  namespaced targetModel IDs work, delete the four custom-endpoint
  playground entries and their Secrets (demo-sandbox) and simplify the
  asset page back to catalog rows only.
