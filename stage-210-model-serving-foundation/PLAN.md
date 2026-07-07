# Stage 210: Implementation Plan

## Scope

Establish the model serving foundation for agent workloads: the exact AI-Q
quickstart model set (rh-ai-quickstart/rh-research, `quickstart` branch)
served on KServe/vLLM, pinned to the Stage 120 GPU layout via hardware
profiles.

## Model Set (confirmed 2026-07-07)

| InferenceService | Model | Hardware profile / resource | Notes |
|------------------|-------|-----------------------------|-------|
| `gpt-oss-120b` | RedHatAI/gpt-oss-120b | `h100-full` (`nvidia.com/gpu: 1`) | Deep-research orchestrator/planner; ~61GiB MXFP4; native Hopper kernels |
| `nemotron-nano-30b` | RedHatAI/NVIDIA-Nemotron-3-Nano-30B-A3B-FP8 | `mig-3g-40gb` | Intent classifier + researcher; ~30GB weights; cap `gpu_memory_utilization` to leave KV headroom in the 40GB slice |
| `nemotron-mini-4b` | nvidia/Nemotron-Mini-4B-Instruct | `mig-2g-20gb` | Document summary model |

Source pattern: `deploy/helm/vllm-models/` chart (ServingRuntime +
InferenceService) from rh-research `quickstart` branch, ported to this repo's
GitOps conventions. Service names must match the endpoints expected by the
AI-Q `values-vllm.yaml` wiring consumed in Stage 320
(`<name>-predictor.<ns>.svc`).

## Components

- [ ] DSC patch to enable KServe
- [ ] vLLM ServingRuntime(s) for the three models
- [ ] 3x InferenceServices pinned to Stage 120 hardware profiles (full H100,
      3g.40gb MIG, 2g.20gb MIG)
- [ ] Model registry entries for the three models
- [ ] Monitoring: UWM ServiceMonitors for vLLM metrics (pattern from
      rh-research `deploy/helm/observability/helm/uwm/`)

## Acceptance Criteria

- KServe is enabled in the DataScienceCluster
- All three model endpoints serve OpenAI-compatible inference requests
- gpt-oss-120b lands on the full-GPU node; Nano-30B and Mini-4B land on
  their intended MIG slices (verified via pod resource requests and node
  placement)
- Monitoring dashboards show inference metrics for all three models

## Dependencies

- Stage 120 (GPU as a Service: 2x p5.4xlarge, MIG layout, hardware profiles)
