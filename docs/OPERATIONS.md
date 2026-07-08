# Operations

This document will contain the active operating model, deployment order,
validation strategy, and day-2 operational notes once stages are implemented.

## Deployment Order

Stages must be deployed in numerical order:

1. Stage 110 - RHOAI Base Platform (GitOps bootstrap, ODF, RHOAI operator)
2. Stage 120 - GPU as a Service (GPU worker, NFD, GPU Operator, Kueue)
3. Stage 210 - Model Serving Foundation (KServe, model endpoint)
4. Stage 220 - Models as a Service (MaaS governance)
5. Stage 310 - NVIDIA NIM Agents (NIM microservices)
6. Stage 320 - Multi-Agent Research (agent orchestration)

## Stage 110 Operating Notes

- **Bootstrap layering**: `stage-110-rhoai-base-platform/deploy.sh` applies
  only the GitOps bootstrap (`gitops/bootstrap/`) and the stage-110 ArgoCD
  Application directly; all other resources are delivered by ArgoCD syncing
  from Git. Never `oc apply -k` the stage trees directly.
- **ArgoCD cluster-admin (demo-only exception)**: the
  `openshift-gitops-argocd-application-controller` service account is bound
  to `cluster-admin` (`gitops/bootstrap/overlays/demo/argocd-rbac.yaml`) so
  stage Applications can manage operators, CRDs, and cluster-scoped CRs.
  Acceptable for this demo per AGENTS.md; not a production pattern.
- **Branch pinning**: during active stage development the stage Application
  `targetRevision` may pin to the working branch (currently
  `feat/stage-110`); restore to `main` when the stage stabilizes.
- **Channel pins**: RHOAI Subscription pins `stable-3.4`; ODF pins
  `stable-4.20` (see `docs/PLATFORM_BASELINE.md`).
- **Cluster guard**: every deploy/validate script sources `.env` and refuses
  to run unless `oc whoami --show-server` matches
  `RHOAI_EXPECTED_API_SERVER`.

## Stage 120 AWS-Side Resources (outside GitOps)

Created 2026-07-07 with the sandbox AWS credentials to reach p5.4xlarge
capacity (us-east-2c had none; AWS pointed to 2a/2b):

- Private subnets in the cluster VPC (`vpc-0dfea38bd1924bcfe`), tagged like
  the installer subnet and associated to the private route table
  (`rtb-006feaf008e66dcde`, NAT in 2c — cross-AZ NAT data charges apply):
  - `cluster-48jqq-hsxrr-subnet-private-us-east-2a` = `subnet-0370a9a14f6b8b07b` (10.0.128.0/20)
  - `cluster-48jqq-hsxrr-subnet-private-us-east-2b` = `subnet-08af499dafecb8123` (10.0.144.0/20)
- GPU MachineSet AZ targeting via `.env`: `RHOAI_GPU_FULL_AZ=us-east-2a`,
  `RHOAI_GPU_MIG_AZ=us-east-2b` (stage-120 `deploy.sh` overrides placement
  and subnet filter per role).
- These subnets are not managed by the RHDP stack; delete them (and the
  route-table associations) before environment teardown if RHDP cleanup
  reports a VPC dependency error.

## Validation Strategy

Each stage provides a `validate.sh` script that checks component health.
Run validation after each stage deployment before proceeding to the next.

## Day-2 Operations

_To be documented as stages are implemented._

## Node Disk Pressure / Evicted Pod Corpses (observed 2026-07-08)

Symptom: a component (e.g., rhods-dashboard) accumulates hundreds of
Failed/ContainerStatusUnknown pods; `oc` list commands time out; one node
reports `DiskPressure=True` (heavy operator image pulls on small workers).

Runbook:
1. `oc get nodes -o custom-columns=...DiskPressure...` to find the node.
2. Delete corpses: `oc delete pods -n <ns> --field-selector=status.phase=Failed`
   (and `=Succeeded`); they are records, not workloads.
3. Kubelet image GC responds to the pressure signal automatically; to
   accelerate: `oc debug node/<node> -- chroot /host crictl rmi --prune`.
4. Consider larger workers if pressure recurs (m6a.4xlarge is tight for
   RHOAI + ODF + MaaS + GPU operator image sets).

## Operator Lifecycle Pins (authoritative; verify BEFORE authoring any Subscription)

Any new operator Subscription MUST be checked against this table, the
relevant rhoai-*/ocp-* skill, and the reference projects (rhoai3-demo,
rhoai3-coding-demo) BEFORE commit. Pinned entries use Manual approval +
an approve-installplan Job that only approves the pinned CSV.

| Operator | Channel | Pin | Why |
|---|---|---|---|
| rhods-operator | stable-3.4 | channel-pinned | demo baseline RHOAI 3.4 |
| rhcl-operator | stable | v1.3.4 Manual | 1.4.x breaks gateway WASM anchoring |
| authorino/limitador/dns operators | stable | v1.3.1 Manual | RHCL 1.3 dependency set |
| cluster-observability-operator | stable | v1.4.0 Manual | 1.5.x breaks RHOAI PersesDatasource (caCert.namespace) |
| kueue-operator | stable-v1.3 | channel-pinned | RHOAI 3.4 external Kueue baseline |
| gpu-operator-certified | v26.3 | channel-pinned | validated MIG mixed strategy |
| opentelemetry-product / tempo-product | stable | channel (per reference) | RHOAI Monitoring prerequisites |
| leader-worker-set | stable-v1.0 | channel-pinned | LLMIS dependency |
| openshift-cert-manager-operator | stable-v1 | adopt existing install | RHCL prerequisite; RHDP-preinstalled on some sandboxes |

## Object Storage (S3) Consumption Model (analysed 2026-07-08)

MCG standalone (stage 110) provides S3: NooBaa `Ready`, default backing
store type `aws-s3`, S3 route `s3-openshift-storage.apps.<domain>`, and
the `openshift-storage.noobaa.io` StorageClass. Consumers claim buckets
with ObjectBucketClaims (OBC) in their own stage - none exist until a
component needs one, so the cluster legitimately shows no buckets today.

RHOAI 3.4 object-storage requirements relevant to this demo:
- Model registry: does NOT use S3 - requires a database (our MySQL,
  validated). Artifact URIs point at OCI modelcars / HF.
- AI pipelines: needs S3 (component is Removed in our DSC).
- MLflow (stage 320): artifact store -> OBC to create in stage 320.
- TempoStack traces (backlog): S3 backend -> OBC when ported.
- Workbench data connections: optional, per-demo content.
