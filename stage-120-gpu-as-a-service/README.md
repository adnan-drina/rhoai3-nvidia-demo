# Stage 120: GPU as a Service

## Why

Multi-agent research workflows require GPU-accelerated inference for large
language models. Enterprise GPU management needs fair scheduling, quota
enforcement, and hardware abstraction so multiple teams can share GPU resources.

## What

- **NVIDIA GPU worker node** via MachineSet
- **Node Feature Discovery** (NFD) for hardware label detection
- **NVIDIA GPU Operator** for driver and runtime management
- **Kueue** for GPU-aware workload scheduling and quota management
- **Hardware Profiles** for abstracting GPU resource requests

## Architecture

```text
OpenShift Cluster
├── GPU Worker Node (NVIDIA L40S)
│   ├── NFD labels
│   └── GPU Operator drivers
├── Kueue
│   ├── ClusterQueue (gpu-reserved)
│   └── LocalQueue (per-namespace)
└── Hardware Profiles
```

## Official Documentation

- [Working with accelerators](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/working_with_accelerators)
- [AI workloads](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/ai_workloads/index)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/)

## Prerequisites

- Stage 110 deployed and validated
