# Operations

Deployment order, day-2 operational notes, and environment-specific records
for the multi-agent research workflows demo.

## Deployment Order

Stages must be deployed in numerical order:

1. Stage 110 — RHOAI Base Platform (GitOps bootstrap, ODF, RHOAI operator)
2. Stage 120 — GPU as a Service (GPU worker, NFD, GPU Operator, Kueue)
3. Stage 210 — Model Serving Foundation (KServe, gateway, Kuadrant, Grafana)
4. Stage 220 — Models as a Service (MaaS governance, Gen AI Studio)
5. Stage 310 — NVIDIA NIM Agents (hosted NVIDIA models via MaaS)
6. Stage 320 — Multi-Agent Research (AI-Q research assistant)

## Validation Strategy

Each stage provides a `validate.sh` script that checks component health.
Run validation after each stage deployment before proceeding to the next.

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
- **Channel pins**: RHOAI Subscription pins `stable-3.4`; ODF pins
  `stable-4.20` (see `docs/PLATFORM_BASELINE.md`).
- **Cluster guard**: every deploy/validate script sources `.env` and refuses
  to run unless `oc whoami --show-server` matches
  `RHOAI_EXPECTED_API_SERVER`.

## Operator Lifecycle Pins

Any new operator Subscription MUST be checked against this table, the
relevant rhoai-\*/ocp-\* skill, and the reference projects (rhoai3-demo,
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

## Object Storage (S3) Consumption Model

MCG standalone (stage 110) provides S3: NooBaa `Ready`, default backing
store type `aws-s3`, S3 route `s3-openshift-storage.apps.<domain>`, and
the `openshift-storage.noobaa.io` StorageClass. Consumers claim buckets
with ObjectBucketClaims (OBC) in their own stage — none exist until a
component needs one, so the cluster legitimately shows no buckets today.

RHOAI 3.4 object-storage requirements relevant to this demo:

- Model registry: does NOT use S3 — requires a database (our MySQL,
  validated). Artifact URIs point at OCI modelcars / HF.
- AI pipelines: needs S3 (component is Removed in our DSC).
- MLflow (stage 320): artifact store -> OBC to create in stage 320.
- TempoStack traces (backlog): S3 backend -> OBC when ported.
- Workbench data connections: optional, per-demo content.

## GPU Arrival Day Runbook

When a p5.4xlarge Machine reaches Running:

1. Node joins with the MIG label from its MachineSet
   (gpu-full=all-disabled, gpu-mig=all-balanced); GPU operator applies
   MIG; verify `oc get nodes -l node-role.kubernetes.io/gpu` allocatable
   shows nvidia.com/gpu or mig-\* resources.
2. Scale local models: for m in gpt-oss-120b nemotron-3-nano-30b-a3b
   nemotron-mini-4b-instruct: `oc patch llminferenceservice $m -n
   models-as-a-service --type merge -p '{"spec":{"replicas":1}}'`
   (replicas are under ignoreDifferences; router-schedulers return
   automatically).
3. Wait LLMIS Ready; stage-210 validate WARNs clear; MaaSModelRefs for
   locals go Ready; local models appear per-tier in /v1/models and the
   playground natively (names aligned to served IDs).
4. Swap AI-Q to local models: update the `aiq-model-wiring` ConfigMap in
   research-agents (BASE_URLs -> $MAAS/{gpt-oss-120b,
   nemotron-3-nano-30b-a3b,nemotron-mini-4b-instruct}; MODEL ids equal to
   those ref names) and restart deploy/aiq-backend. Hosted wiring remains
   the documented fallback (Option 2).
5. Re-run validate.sh for stages 120/210/320.

## Environment-Specific Records

### AWS GPU Subnets (cluster-specific)

GPU MachineSets may need subnets in specific AZs depending on p5.4xlarge
capacity. Stage 120 `deploy.sh` supports `RHOAI_GPU_FULL_AZ` and
`RHOAI_GPU_MIG_AZ` overrides in `.env`.

If hand-made subnets were created for multi-AZ GPU search, tag them with
`demo.rhoai.io/hand-made=true` and delete them before environment
teardown to avoid VPC dependency errors during RHDP cleanup.
