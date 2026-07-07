# GitOps Source Tree

This directory contains the active GitOps manifests for the RHOAI NVIDIA demo.

## Layout

```text
gitops/
├── bootstrap/                    # ArgoCD operator and instance bootstrap
│   ├── base/                     # Subscription + OperatorGroup
│   └── overlays/
│       ├── operator/             # GitOps operator channel pin
│       └── demo/                 # ArgoCD instance, AppProject, cluster-admin
├── argocd/
│   └── app-of-apps/              # ArgoCD Application manifests (one per stage)
├── stage-110-rhoai-base-platform/
├── stage-120-gpu-as-a-service/
├── stage-210-model-serving-foundation/
├── stage-220-models-as-a-service/
├── stage-310-nvidia-nim-agents/
├── stage-320-multi-agent-research/
└── stage-330-agent-evaluation/
```

## Conventions

- Each stage uses Kustomize with `base/` directories
- ArgoCD Applications use `project: rhoai-nvidia-demo`
- `resourceTrackingMethod: annotation`
- Operator GitOps follows Red Hat Community of Practice patterns
- No direct `oc apply -k` on ArgoCD-managed resources
