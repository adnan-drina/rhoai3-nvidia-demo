# Stage 320: Implementation Plan

## Scope

Deploy the AI-Q multi-agent research application (rh-ai-quickstart/rh-research,
`quickstart` branch) on the platform built by Stages 110-310: orchestration
node, clarifier, shallow researcher, and deep researcher backed by the
MaaS-governed model endpoints.

## GitOps Decision Record (2026-07-07)

No Helm in this project (user decision). The rh-research charts
(`deploy/helm/aiq-rh/`, `deploy/helm/vllm-models/`) are reference source
only; all manifests are ported into plain Kustomize under
`gitops/stage-320-multi-agent-research/` and owned by this repo. Cost
accepted: upstream chart changes must be ported manually; pin the reference
to a specific rh-research ref and record it here when porting.

## Components

- [ ] Namespace + Kustomize base ported from the aiq-rh chart templates:
      backend Deployment/Service (nvcr.io/nvidia/blueprint/aiq-agent),
      frontend Deployment/Service/Route (nvcr.io/nvidia/blueprint/aiq-frontend),
      Postgres (Deployment/PVC/init ConfigMap)
- [ ] Workflow ConfigMap: project-owned adaptation of `config_web_vllm.yml`
      pointing `VLLM_*_BASE_URL` at Stage 220 MaaS endpoints with a
      MaaS-minted `VLLM_API_KEY`
- [ ] Researcher-swap config variant (Super-120B via Stage 310 external
      model) for the live governance demo beat
- [ ] Secrets (external, never committed): `aiq-credentials` (DB user/pass,
      `TAVILY_API_KEY`, optional `SERPER_API_KEY`), `ngc-api` image pull
      secret for nvcr.io
- [ ] Data sources: Tavily web search enabled; Serper paper search optional;
      LlamaIndex/Chroma knowledge layer as the baseline knowledge backend
- [ ] MLflow tracing (part of the quickstart app chart, so in scope here):
      OTel exporter with redaction pointed at the RHOAI MLflow endpoint
      (`mlflow.redhat-ods-applications.svc:8443/v1/traces`), plus the
      MLflow token secret and RBAC ported from the aiq-rh templates
- [ ] Demo research workflow script (shallow cited answer -> clarifier ->
      async deep-research report)

## Acceptance Criteria

- Backend, frontend, and Postgres pods are healthy; UI reachable via Route
- Shallow research returns a cited answer using the local Nano-30B
  researcher through MaaS
- Deep research completes an async job and produces a citation-backed
  report using local gpt-oss-120b as orchestrator
- Researcher model swap to external nemotron-3-super-120b-a12b works via
  config change only
- Agent interactions are traced end-to-end and visible in the RHOAI MLflow
  experiment UI (with input/output redaction enabled)
- No secret material or API key appears in Git

## Dependencies

- Stage 310 (NVIDIA NIM external models)
- Tavily API key (required for web research); Serper API key (optional)
