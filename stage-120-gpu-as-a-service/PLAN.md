# Stage 120: Implementation Plan

## Scope

Enable GPU infrastructure for AI workloads using a two-node H100 layout that
demonstrates both full-GPU and MIG (Multi-Instance GPU) consumption models,
following the Red Hat GPU-as-a-Service pattern (Kueue + MIG + hardware
profiles).

## Confirmed Architecture (2026-07-07)

Two AWS `p5.4xlarge` instances (1x NVIDIA H100 80GB each, ~$6.88/hr on-demand
each), sized for the exact AI-Q quickstart model set served in Stage 210:

| Node | MIG mode | Serves | Resources exposed |
|------|----------|--------|-------------------|
| gpu-full | `all-disabled` (full GPU) | RedHatAI/gpt-oss-120b (orchestrator, ~61GiB MXFP4 weights) | `nvidia.com/gpu: 1` |
| gpu-mig | `all-balanced` (mixed strategy) | Nemotron-3-Nano-30B-A3B-FP8 (3g.40gb), Nemotron-Mini-4B (2g.20gb), 2x 1g.10gb spare | `nvidia.com/mig-3g.40gb`, `nvidia.com/mig-2g.20gb`, `nvidia.com/mig-1g.10gb` |

Rationale: gpt-oss-120b is validated for a single 80GB H100 and cannot span
MIG slices (vLLM cannot tensor-parallel across MIG); the smaller models fit
the GPU Operator's built-in `all-balanced` MIG profile with no custom MIG
ConfigMap. MIG requires A30/A100/H100-class GPUs, ruling out L40S/L4/A10G
instance families. Decision record: Option A selected over a single
g6e.12xlarge (4x L40S) standard deployment, which offers no MIG support and
runs gpt-oss-120b on a community-supported Marlin fallback kernel.

## Components

- [ ] GPU worker MachineSets: 2x `p5.4xlarge` (gpu-full, gpu-mig) with
      per-node labels for MIG config selection
- [ ] NFD operator and NodeFeatureDiscovery
- [ ] NVIDIA GPU Operator with `mig.strategy: mixed`; MIG Manager applies
      `all-disabled` (gpu-full) and `all-balanced` (gpu-mig) via
      `nvidia.com/mig.config` node labels
- [ ] Kueue operator; ClusterQueue covering `nvidia.com/gpu`,
      `nvidia.com/mig-3g.40gb`, `nvidia.com/mig-2g.20gb`,
      `nvidia.com/mig-1g.10gb`; LocalQueue(s) for demo namespaces
- [ ] Hardware profiles: `h100-full` (full GPU), `mig-3g-40gb`,
      `mig-2g-20gb` (and optionally `mig-1g-10gb` for workbenches), each
      bound to its LocalQueue
- [ ] DSC patch to enable Kueue

## Acceptance Criteria

- Both GPU worker nodes are running with NVIDIA drivers
- NFD labels are applied to GPU nodes
- gpu-full node exposes `nvidia.com/gpu: 1`; gpu-mig node exposes the
  all-balanced MIG resources (1x 3g.40gb, 1x 2g.20gb, 2x 1g.10gb)
- Kueue ClusterQueue admits workloads for all four resource types
- Hardware profiles are available in the RHOAI dashboard and route
  deployments to the intended node/slice

## Pre-Deployment Checks (AWS)

- Verify `p5.4xlarge` on-demand availability in the target region
  (launched in us-east-1/2, us-west-2, London, Mumbai, Sydney, Tokyo,
  Sao Paulo); EC2 Capacity Block is the fallback for demo day
- Request "Running On-Demand P instances" quota >= 32 vCPUs

## Dependencies

- Stage 110 (RHOAI base platform)
