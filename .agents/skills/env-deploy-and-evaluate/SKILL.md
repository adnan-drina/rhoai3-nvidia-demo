---
name: env-deploy-and-evaluate
metadata:
  version: 1.0.0
  platform-family: env
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Demo Environment"
---

# Deploy and Evaluate

## Purpose

Guide deployment and evaluation of stages on a live OpenShift cluster.

## Pre-Deployment Checklist

1. Verify `.env` is configured with `RHOAI_EXPECTED_API_SERVER`
2. Verify `oc whoami --show-server` matches the expected cluster
3. Verify previous stages are deployed and validated

## Deployment Pattern

```bash
# Source environment
source .env

# Deploy stage
./stage-YXX-slug/deploy.sh

# Validate stage
./stage-YXX-slug/validate.sh
```

## Post-Deployment Validation

Each stage `validate.sh` should check:
- Operator CSVs are `Succeeded`
- Pods are `Running`/`Completed`
- CRDs and CRs are in expected state
- ArgoCD Application is `Synced` and `Healthy`
