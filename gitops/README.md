# GitOps Source Tree

Kustomize manifests synced to the cluster by ArgoCD. Each stage directory maps
to an ArgoCD Application in `argocd/app-of-apps/`.

## Layout

```text
gitops/
├── bootstrap/                           ArgoCD operator and instance bootstrap
│   ├── base/                            Subscription + OperatorGroup
│   └── overlays/
│       ├── operator/                    GitOps operator channel pin
│       └── demo/                        ArgoCD instance, AppProject, cluster-admin
├── argocd/
│   └── app-of-apps/                     ArgoCD Application manifests (one per stage)
├── stage-110-rhoai-base-platform/       ODF MCG, RHOAI operator + instance CRs, Model Registry
├── stage-120-gpu-as-a-service/          NFD, GPU Operator, ClusterPolicy, Kueue, hardware profiles
├── stage-210-model-serving-foundation/  KServe activation, RHCL/Kuadrant, Gateway, Grafana, LLMISVCs
├── stage-220-models-as-a-service/       MaaS DB, model registrations, subscriptions, dashboard flags
├── stage-310-nvidia-nim-agents/         Hosted NVIDIA ExternalModels, subscription tiers, AuthPolicies
└── stage-320-multi-agent-research/      AI-Q backend + frontend + PostgreSQL, console link, dashboard tile
```

## Conventions

- Each stage uses Kustomize with `base/` directories
- ArgoCD Applications use `project: rhoai-nvidia-demo`
- `resourceTrackingMethod: annotation`
- Operator GitOps follows Red Hat Community of Practice patterns
- No direct `oc apply -k` on ArgoCD-managed resources
