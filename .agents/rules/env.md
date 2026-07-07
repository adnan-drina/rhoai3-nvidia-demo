---
name: env
skill-group: Demo Environment
skill-prefix: env-
applies-to:
  - .env.example
  - env.example
  - docs/OPERATIONS.md
  - docs/TROUBLESHOOTING.md
  - scripts/bootstrap.sh
  - scripts/lib.sh
  - scripts/validate-lib.sh
  - stage-*/deploy.sh
  - stage-*/validate.sh
---

# Demo Environment

Use the `env-*` skills as the source of truth for work with live AWS/OpenShift
demo environments:

- `.agents/skills/env-deploy-and-evaluate/SKILL.md`
- `.agents/skills/env-troubleshoot/SKILL.md`
- `.agents/skills/env-manage-resources/SKILL.md`

No active bootstrap, deploy, validate, or resource-management scripts exist
until they are introduced under `scripts/` or root-level `stage-YXX-slug/`
folders.

Before live cluster work, load the repo-local environment, verify the expected
API server guard, and keep credentials scoped to this project. Do not bypass the
OpenShift safety guard without explicit user confirmation.

When the environment automation is created, use GitOps and per-stage scripts
for environment changes. Keep operational runbooks in `docs/OPERATIONS.md` and
recovery guidance in `docs/TROUBLESHOOTING.md`.

When operator or controller pods fail after API-server instability, first
inspect ClusterOperator health, pod logs, events, and leader-election/API
timeout messages. If the owning Deployment is operator-managed and the desired
state is otherwise healthy, deleting the failed pod to let it recreate is a
live recovery action only. Do not convert that into GitOps image pins,
generated Deployment patches, or copied generated resources.
