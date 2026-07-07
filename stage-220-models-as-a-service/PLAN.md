# Stage 220: Implementation Plan

## Scope

Enable governed model access for agent workloads: one MaaS governance plane
over both the self-hosted Stage 210 models (local) and NVIDIA-hosted NIM
endpoints (external).

## Model Governance Split (confirmed 2026-07-07)

Demo narrative: local = sovereignty (research data and core workflow stay on
the cluster), external = frontier reach (models beyond the local GPU
footprint), MaaS = one governance plane over both.

| Tier | Model | Backend |
|------|-------|---------|
| Local | RedHatAI/gpt-oss-120b | Stage 210 vLLM InferenceService (full H100) |
| Local | RedHatAI/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8 | Stage 210 vLLM InferenceService (MIG 3g.40gb) |
| Local | nvidia/Nemotron-Mini-4B-Instruct | Stage 210 vLLM InferenceService (MIG 2g.20gb) |
| External | nvidia/nemotron-3-super-120b-a12b | NVIDIA API Catalog (integrate.api.nvidia.com) via Stage 310 |

AI-Q (Stage 320) consumes MaaS endpoints and a MaaS-minted key through its
standard OpenAI-compatible wiring (`VLLM_*_BASE_URL` / `VLLM_API_KEY`) — no
application changes required to add governance.

## Components

- [ ] MaaS Gateway prerequisites
- [ ] MaaS Gateway configuration
- [ ] Local model registration (3x Stage 210 endpoints)
- [ ] External model registration (NVIDIA API Catalog; model onboarding
      detail in Stage 310)
- [ ] API key management (per-subscription keys for the AI-Q workload and
      for demo user personas)
- [ ] DSC patch for MaaS

## Acceptance Criteria

- MaaS Gateway is running and healthy
- All three local models accessible through MaaS API
- External model accessible through the same MaaS API and key discipline
- API keys can be minted per subscription
- A single OpenAI-compatible client can hit local and external models by
  switching only model name / endpoint path

## Dependencies

- Stage 210 (model serving foundation)
