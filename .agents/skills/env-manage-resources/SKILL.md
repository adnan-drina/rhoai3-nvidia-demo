---
name: env-manage-resources
metadata:
  version: 1.0.0
  platform-family: env
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Demo Environment"
---

# Manage Resources

## Purpose

Guide resource management for the demo environment including GPU scheduling,
namespace quotas, and cluster capacity.

## GPU Resource Management

- NVIDIA H100 GPU workers (AWS p5.4xlarge) managed through MachineSets;
  one full-GPU node and one MIG-partitioned node (see stage-120 PLAN.md)
- Kueue ClusterQueues and LocalQueues for GPU scheduling
- Hardware profiles for workload GPU requests

## Namespace Management

| Stage | Namespace(s) |
|-------|-------------|
| 110 | `openshift-gitops`, `openshift-storage`, `redhat-ods-*` |
| 120 | GPU node labels, Kueue queues |
| 210 | `demo-sandbox` |
| 220 | `models-as-a-service` |
| 310 | `nvidia-nim-agents` |
| 320 | `multi-agent-research` |
