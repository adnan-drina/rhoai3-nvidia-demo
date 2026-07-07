---
name: nvidia-nemo-guardrails
metadata:
  version: 1.0.0
  platform-family: nvidia
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "NVIDIA Integration"
---

# NVIDIA NeMo Guardrails

## Purpose

Guide the deployment and configuration of NeMo Guardrails for agent safety
on Red Hat OpenShift AI.

## What is NeMo Guardrails

NeMo Guardrails is an open-source toolkit for adding programmable guardrails
to LLM-based applications. For multi-agent research workflows, guardrails
ensure:

- Input validation and topic steering
- Output safety and factual grounding
- Agent interaction policy enforcement
- Compliance with enterprise research policies

## Integration with Multi-Agent Workflows

- Guardrails can be applied at the MaaS gateway level (Stage 220)
- Per-agent guardrails for specialized safety policies
- Workflow-level guardrails for end-to-end research compliance
- Observability through OpenTelemetry traces

## Deployment Pattern

NeMo Guardrails deploys as a service that proxies model requests:
1. Guardrails service configuration in ConfigMaps
2. MaaS API key for model access
3. OpenTelemetry collector for trace export
4. Kustomize manifests in GitOps tree

## Source Documentation

- NeMo Guardrails: https://docs.nvidia.com/nemo/guardrails/
- RHOAI Guardrails: see `docs/PLATFORM_BASELINE.md` guardrails section
