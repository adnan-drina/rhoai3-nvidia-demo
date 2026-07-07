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

## Validation Strategy

Each stage provides a `validate.sh` script that checks component health.
Run validation after each stage deployment before proceeding to the next.

## Day-2 Operations

_To be documented as stages are implemented._
