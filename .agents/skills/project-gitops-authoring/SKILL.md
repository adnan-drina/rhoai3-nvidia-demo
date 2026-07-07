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

Follow the Red Hat Community of Practice catalog structure:

```text
component/
  operator/base/          # Subscription, OperatorGroup, Namespace
  operator/overlays/      # Channel pin
  instance/base/          # CR operands
  aggregate/overlays/demo/
```

## Constraints

- `resourceTrackingMethod: annotation`
- `project: rhoai-nvidia-demo`
- No direct `oc apply -k` on ArgoCD-managed resources
- Operator images owned by OLM, not project GitOps
