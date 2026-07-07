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

## Official Documentation

- [Installing OpenShift AI Self-Managed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.4/html/installing_and_uninstalling_openshift_ai_self-managed)
- [OpenShift GitOps](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/gitops/index)
- [ODF 4.20](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/4.20/)

## Prerequisites

- OpenShift Container Platform 4.20 cluster
- Cluster admin access
