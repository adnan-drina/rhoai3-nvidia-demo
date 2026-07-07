# Stage 110: RHOAI Base Platform

## Why

Every enterprise AI platform needs a governed, repeatable foundation. GitOps
ensures that platform state is declarative, auditable, and recoverable. Red Hat
OpenShift AI provides the managed AI/ML platform layer on top of OpenShift.

## What

- **OpenShift GitOps** (ArgoCD) bootstrap for declarative platform management
- **OpenShift Data Foundation** MCG for S3-compatible object storage
- **Red Hat OpenShift AI** operator, DataScienceCluster, and DSCInitialization
- **Model Registry** for centralized model artifact management
- **Demo access** configuration for admin and developer personas

## Architecture

This stage establishes the foundation that all subsequent stages build upon:

```text
OpenShift Cluster
├── openshift-gitops (ArgoCD)
├── openshift-storage (ODF MCG)
├── redhat-ods-operator (RHOAI)
├── rhoai-model-registries
└── demo-sandbox
```

## Deployment Model

- `deploy.sh` bootstraps the one layer ArgoCD cannot manage for itself:
  the OpenShift GitOps operator, the ArgoCD instance
  (`resourceTrackingMethod: annotation`), the `rhoai-nvidia-demo`
  AppProject, and the controller cluster-admin binding (demo-only,
  documented in `docs/OPERATIONS.md`).
- Everything else is delivered by the `stage-110-rhoai-base-platform`
  ArgoCD Application syncing `gitops/stage-110-rhoai-base-platform/` from
  Git: ODF operator (`stable-4.20`), RHOAI operator pinned to the
  `stable-3.4` channel, then the verified instance CRs (standalone MCG
  StorageCluster, DSCInitialization, DataScienceCluster, Model Registry).
- KServe serving configuration arrives in Stage 210 and Kueue in Stage 120;
  this stage keeps those components at their defaults.

## Official Documentation

- [Installing OpenShift AI Self-Managed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/installing_and_uninstalling_openshift_ai_self-managed)
- [OpenShift GitOps](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/gitops/index)
- [ODF 4.20](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/)

## Prerequisites

- OpenShift Container Platform 4.20 cluster
- Cluster admin access
