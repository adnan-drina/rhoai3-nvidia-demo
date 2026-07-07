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

Each stage contributes a new `components/<feature>/` directory plus one
line in `overlays/demo/kustomization.yaml` (commented with the owning
stage). The base manifest stays pristine, and exactly one ArgoCD
Application (the owning stage's) renders the shared CR.

## Constraints

- `resourceTrackingMethod: annotation`
- `project: rhoai-nvidia-demo`
- No direct `oc apply -k` on ArgoCD-managed resources
- Operator images owned by OLM, not project GitOps
