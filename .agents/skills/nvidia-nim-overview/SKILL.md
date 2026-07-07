---
name: nvidia-nim-overview
metadata:
  version: 1.0.0
  platform-family: nvidia
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "NVIDIA Integration"
---

# NVIDIA NIM Overview

## Purpose

Guide the deployment and integration of NVIDIA NIM (NVIDIA Inference
Microservices) on Red Hat OpenShift AI.

## What is NIM

NVIDIA NIM is a set of accelerated inference microservices that allow
organizations to deploy AI models as optimized, production-ready containers.
NIM provides:

- Pre-optimized inference for LLMs, vision, and embedding models
- OpenAI-compatible API endpoints
- GPU-optimized runtimes with TensorRT-LLM
- Container images from NVIDIA NGC catalog

## Integration with RHOAI

- NIM containers can be deployed as KServe InferenceServices on RHOAI
- GPU scheduling through Kueue and hardware profiles
- Model governance through MaaS gateway
- Monitoring through OpenShift observability stack

## Deployment Pattern on OpenShift

NIM containers follow the same GitOps pattern as other RHOAI workloads:
1. Kustomize manifests in `gitops/stage-310-nvidia-nim-agents/`
2. ArgoCD Application for sync
3. Deploy script for secrets and NGC pull credentials
4. Validate script for health checks

## Source Documentation

- NVIDIA NIM documentation: https://docs.nvidia.com/nim/
- NVIDIA NGC catalog: https://catalog.ngc.nvidia.com/
- RHOAI model serving: `docs/PLATFORM_BASELINE.md`
