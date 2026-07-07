# Stage 310: Implementation Plan

## Scope

NVIDIA NIM for agentic AI workloads, following the rh-research quickstart
pattern: NIM is consumed as NVIDIA-hosted endpoints on the NVIDIA API Catalog
(`integrate.api.nvidia.com`, `_type: nim` in AI-Q configs), registered as
external models in the Stage 220 MaaS gateway.

## Scope Decision Record (2026-07-07)

The original scope ("NIM containers running on GPU nodes") is replaced.
Rationale, accepted by the user: the quickstart itself never deploys NIM
containers on-cluster — its NIM usage is the hosted API Catalog in default
and FRAG modes, while self-hosted serving uses vLLM/KServe (our Stage 210).
Following the quickstart as closely as possible means hosted NIM as the
external model tier. On-cluster NIM microservices appear in the quickstart
ecosystem only inside the NVIDIA RAG Blueprint (FRAG knowledge layer), which
is recorded below as an optional future extension, not stage scope.

## Components

- [ ] `NVIDIA_API_KEY` secret handling (external, never committed; NVIDIA
      Build API key)
- [ ] External model onboarding in MaaS: `nvidia/nemotron-3-super-120b-a12b`
      (premium deep-research researcher/agent model — the quickstart's
      documented optional upgrade, infeasible on the local 2-GPU footprint)
- [ ] Optional external registrations: `nvidia/llama-nemotron-embed-vl-1b-v2`
      and `nvidia/nemotron-nano-12b-v2-vl` (knowledge-layer embedding/VLM,
      enable if/when document upload is demoed)
- [ ] Optional burst/failover registrations: hosted twins of gpt-oss-120b
      and Nemotron Nano 30B (demo-day insurance; orchestrator can flip to
      hosted NIM via config change under the same MaaS governance)
- [ ] AI-Q config artifact enabling the Super-120B researcher swap (used as
      a live demo beat in Stage 320)
- [ ] Endpoint validation (chat completion against each registered NIM
      model through MaaS)

## Acceptance Criteria

- Hosted NIM endpoints are registered in MaaS and respond to inference
  requests through MaaS-minted keys
- The deep-research workflow can switch its researcher model to
  nemotron-3-super-120b-a12b via configuration only (no infra change)
- No NVIDIA API key is exposed to end clients; only MaaS keys circulate

## Future / Deferred (labeled, not claimed)

- On-cluster NIM microservices via the NVIDIA RAG Blueprint (FRAG knowledge
  layer, `values-vllm-frag` pattern; rh-ai-quickstart
  `nvidia-blueprint-enterprise-rag-pipeline`). Requires GPU capacity beyond
  the Stage 120 2x p5.4xlarge layout (embedding/reranking/ingestion NIMs).
  Revisit only with an explicit capacity decision.

## Dependencies

- Stage 220 (Models as a Service)
- NVIDIA API key for API Catalog access

## E2E Status (2026-07-07)

- Persona-based governed E2E: key mint/revoke, tier-scoped /v1/models
  visibility, gateway auth, path rewrite, and provider-key injection all
  verified working (13/15; header-echo tap proved byte-exact injection).
- Remaining blocker is the credential itself: .env NVIDIA_API_KEY is an
  NGC-style key (84 chars, no nvapi- prefix). integrate.api.nvidia.com
  completions require an nvapi- API key from build.nvidia.com
  (/v1/models there is unauthenticated - do not use it as a key check).
  ACTION (user): replace NVIDIA_API_KEY in .env with an nvapi- key, rerun
  stage-310 deploy.sh (recreates the secret) and validate.sh.
