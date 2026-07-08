---
name: project-gitops-authoring
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# GitOps Authoring

## Purpose

Conventions for authoring GitOps manifests in this repository.

## ArgoCD Application Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: stage-YXX-slug
  namespace: openshift-gitops
spec:
  project: rhoai-nvidia-demo
  source:
    repoURL: <GIT_REPO_URL>
    targetRevision: <GIT_REPO_BRANCH>
    path: gitops/stage-YXX-slug
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Kustomize Structure

```text
gitops/stage-YXX-slug/
├── kustomization.yaml
├── component-a/
│   └── base/
│       ├── kustomization.yaml
│       └── *.yaml
└── component-b/
    └── base/
        ├── kustomization.yaml
        └── *.yaml
```

## Operator GitOps Pattern

Follow the Red Hat Community of Practice catalog structure
(https://github.com/redhat-cop/gitops-catalog):

```text
component/
  operator/base/          # Subscription, OperatorGroup, Namespace
  operator/overlays/      # Channel pin
  instance/base/          # CR operands
  aggregate/overlays/demo/
```

## Shared-CR Composition Pattern (CoP components)

When a later stage needs to change a CR owned by an earlier stage (for
example the Stage 110 DataScienceCluster), NEVER edit the owning stage's
base manifest. Follow the gitops-catalog `openshift-ai` pattern:

```text
owner-stage/rhoai/instance/
  base/datasciencecluster.yaml     # pristine: every component Removed
  components/<feature>/            # kind: Component (kustomize.config.k8s.io/v1alpha1)
    kustomization.yaml             #   patches: path + target {kind: DataScienceCluster}
    patch-datasciencecluster.yaml  #   minimal spec fragment
  overlays/demo/kustomization.yaml # resources: ../../base + components list
```

Use `components/` overlays only for features owned by the SAME stage that
renders the CR. For CROSS-STAGE activation (a later stage enabling a DSC
component), follow the proven rhoai3-demo pattern instead - the product
recommendation is that components whose operators/prerequisites are not
yet installed stay `Removed`:

- the owner's base manifest keeps later-stage components explicitly
  `Removed`;
- the owner's ArgoCD Application lists those component fields under
  `ignoreDifferences` (so selfHeal never reverts an activation);
- each owning stage ships a `dsc-activation` sync-hook Job (SA + RBAC +
  `oc patch --type merge`), sync-waved AFTER the component's
  prerequisites exist in that stage.

This generalizes to ANY hook-patched field (e.g., the MaaS gateway
hostname patched to the real cluster domain): the owning Application MUST
pair `ignoreDifferences` (jsonPointers for the patched fields) with
`RespectIgnoreDifferences=true` in syncOptions. ignoreDifferences alone
only masks drift detection - a sync apply still stomps the field back to
the Git value (this tore down the MaaS gateway chain on 2026-07-08 while
every app reported Synced/Healthy). Mark platform-critical CRs
(Gateway, Kuadrant, Authorino, LeaderWorkerSetOperator) with
`Prune=false` so no transient render can prune them, and install the
Subscription health Lua (ArgoCD extraConfig) whenever pinned Manual
subscriptions participate in sync waves.

## Constraints

- `resourceTrackingMethod: annotation`
- `project: rhoai-nvidia-demo`
- No direct `oc apply -k` on ArgoCD-managed resources
- Operator images owned by OLM, not project GitOps
