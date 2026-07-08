# Stage 110: Implementation Plan

## Scope

Bootstrap the GitOps-managed RHOAI platform foundation on the active sandbox
(OCP 4.20.26, us-east-2). All product versions pin to
`docs/PLATFORM_BASELINE.md`; the RHOAI Subscription pins to the `stable-3.4`
channel (verified present in the cluster catalog).

## Components

- [x] GitOps bootstrap (script-applied, the one non-ArgoCD-managed layer):
      OpenShift GitOps operator Subscription, ArgoCD instance with
      `resourceTrackingMethod: annotation`, AppProject `rhoai-nvidia-demo`,
      application-controller cluster-admin ClusterRoleBinding (documented in
      `docs/OPERATIONS.md`)
- [x] Stage 110 ArgoCD Application (app-of-apps entry) syncing
      `gitops/stage-110-rhoai-base-platform/`
- [x] ODF MCG: `openshift-storage` namespace, OperatorGroup, `odf-operator`
      Subscription (`stable-4.20`); standalone Multicloud Object Gateway
      StorageCluster (NooBaa + default backing store on AWS)
- [x] RHOAI: `redhat-ods-operator` namespace, OperatorGroup,
      `rhods-operator` Subscription (channel `stable-3.4`, installed CSV
      rhods-operator.3.4.2); DSCInitialization auto-created by the operator
      (not authored); DataScienceCluster v2 with dashboard, workbenches, and
      model registry managed — serving (KServe) is configured in Stage 210,
      Kueue in Stage 120
- [x] Model Registry: registries namespace and ModelRegistry instance backed
      by an in-cluster MySQL (DB secret created by `deploy.sh`, never
      committed)
- [x] Demo access (`setup-access.sh`): htpasswd identity provider with
      `ai-admin`, `ai-developer`, and `ai-researcher` users (passwords from
      `.env` or generated), groups, and RHOAI admin-group wiring (login
      verified live 2026-07-07)

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

## Doc Coverage (audit 2026-07-07)

- Operator install (stable-3.4, CSV 3.4.2), auto-created DSCInitialization,
  DSC v2 via CoP components, ODF MCG standalone (NooBaa/backingstore/S3
  route), model registry + MySQL + registry RBAC, htpasswd IdP + groups +
  Auth CR wiring: applied.
- Demo persona RBAC on demo-sandbox + registry role bindings: applied (was
  a gap; found in audit - dashboard project visibility is RBAC-driven).
- Workbench images present (20 imagestreams); self-provisioning active for
  authenticated users.
- Not applied, deliberate: idle notebook culling, custom notebook sizes,
  cert customization (self-signed policy), disconnected/mirror setup (N/A),
  usage telemetry left default.

## Post-Replay Additions (2026-07-08)

- ODF console plugin enablement (proven hook trio) - Data Foundation
  status in the OpenShift console; StorageSystem CRD absent in ODF 4.20
  by design. S3 consumption model documented in docs/OPERATIONS.md.
