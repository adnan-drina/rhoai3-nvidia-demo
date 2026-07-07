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
- [x] 3x InferenceServices pinned to Stage 120 hardware profiles (full H100,
      3g.40gb MIG, 2g.20gb MIG) — deployed; Ready pending GPU capacity
- [ ] Model registry entries for the three models (register once model pods
      are Running)
- [ ] Monitoring: UWM ServiceMonitors for vLLM metrics (pattern from
      rh-research `deploy/helm/observability/helm/uwm/`; author once pods
      exist to scrape)

## Implementation Notes (live findings, 2026-07-07)

- validate.sh: 6 passed, 0 failed, 4 GPU-capacity warnings. KServe enabled
  via the stage-110 CoP component patch `components/kserve`.
- ServingRuntime uses the RHOAI 3.4 GA image from the shipped
  `vllm-cuda-runtime-template` (digest-pinned, vLLM v0.18.0), not the
  quickstart's early-access image; /dev/shm volume and probes added per the
  rh-research chart.
- RHOAI 3.4 KServe normalizes `serving.kserve.io/deploymentMode:
  RawDeployment` to `Standard` — Git must say `Standard`. KServe also drops
  empty `model.name` fields.
- The `hardwareprofile-isvc-injector` webhook accepted our
  `opendatahub.io/hardware-profile-name` annotations; explicit resources,
  tolerations, and the `kueue.x-k8s.io/queue-name: default` label remain the
  deterministic GitOps truth and matched post-injection.

## Acceptance Criteria

- KServe is enabled in the DataScienceCluster
- All three model endpoints serve OpenAI-compatible inference requests
- gpt-oss-120b lands on the full-GPU node; Nano-30B and Mini-4B land on
  their intended MIG slices (verified via pod resource requests and node
  placement)
- Monitoring dashboards show inference metrics for all three models

## Dependencies

- Stage 120 (GPU as a Service: 2x p5.4xlarge, MIG layout, hardware profiles)

## Doc Coverage (audit 2026-07-07) and REQUIRED REWORK

- Serving runtime from RHOAI GA template, RawDeployment("Standard") ISVCs,
  modelcar storage, hardware-profile annotations, GPU tolerations: applied.
- Model metrics path: UWM enabled + disableKServeMetrics/
  disablePerformanceMetrics pinned false (audit fix); per-model dashboards
  activate when pods run.
- vLLM ServiceMonitors + registry entries: deferred until model pods exist.
- **REQUIRED REWORK (audit finding)**: RHOAI 3.4 MaaS can only govern
  `LLMInferenceService` (v1alpha1/v1alpha2 CRD present) or `ExternalModel` -
  `MaaSModelRef.spec.modelRef.kind` has no InferenceService option. The
  quickstart avoids this by bypassing MaaS; our architecture routes all
  model access through MaaS. Decision needed: convert the three
  InferenceServices to LLMInferenceService (aligns with MaaS + native
  Gateway API routing; needs schema port of runtime/args/modelcar URIs) vs
  keep ISVCs and give AI-Q direct endpoints (loses governed-local story).
  Recommendation: convert. GPU-blocked either way, so no rework cost lost.
