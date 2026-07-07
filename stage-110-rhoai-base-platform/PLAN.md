# Stage 110: Implementation Plan

## Scope

Bootstrap the GitOps-managed RHOAI platform foundation on the active sandbox
(OCP 4.20.26, us-east-2). All product versions pin to
`docs/PLATFORM_BASELINE.md`; the RHOAI Subscription pins to the `stable-3.4`
channel (verified present in the cluster catalog).

## Components

- [ ] GitOps bootstrap (script-applied, the one non-ArgoCD-managed layer):
      OpenShift GitOps operator Subscription, ArgoCD instance with
      `resourceTrackingMethod: annotation`, AppProject `rhoai-nvidia-demo`,
      application-controller cluster-admin ClusterRoleBinding (documented in
      `docs/OPERATIONS.md`)
- [ ] Stage 110 ArgoCD Application (app-of-apps entry) syncing
      `gitops/stage-110-rhoai-base-platform/`
- [ ] ODF MCG: `openshift-storage` namespace, OperatorGroup, `odf-operator`
      Subscription (`stable-4.20`); standalone Multicloud Object Gateway
      StorageCluster (NooBaa + default backing store on AWS)
- [ ] RHOAI: `redhat-ods-operator` namespace, OperatorGroup,
      `rhods-operator` Subscription (channel `stable-3.4`);
      DSCInitialization; DataScienceCluster with dashboard, workbenches, and
      model registry managed — serving (KServe) is configured in Stage 210,
      Kueue in Stage 120
- [ ] Model Registry: registries namespace and ModelRegistry instance backed
      by an in-cluster MySQL (DB secret created by `deploy.sh`, never
      committed)
- [ ] Demo access (`setup-access.sh`): htpasswd identity provider with
      `ai-admin` and `ai-developer` users (passwords from `.env` or
      generated), groups, and RHOAI admin-group wiring

## Field Verification Rule

CR manifests (StorageCluster, DSCInitialization, DataScienceCluster,
ModelRegistry, Auth) are committed only after verifying field names against
the live cluster CRDs (`oc explain`, `oc get crd`) once the operators are
installed. Two-commit flow: (1) operators + bootstrap, (2) verified instance
CRs.

## Acceptance Criteria

- ArgoCD instance is running with annotation tracking and manages the
  `rhoai-nvidia-demo` project; stage-110 Application reports Synced/Healthy
- ODF MCG NooBaa reports Ready and exposes the S3 endpoint
- RHOAI operator is at a `stable-3.4` CSV; DataScienceCluster reports Ready
- Model Registry is accessible
- Demo users can log in with assigned roles

## Dependencies

None (this is the foundation stage).
