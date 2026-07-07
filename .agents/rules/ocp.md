---
name: ocp
skill-group: OpenShift Platform
skill-prefix: ocp-
applies-to:
  - docs/PLATFORM_BASELINE.md
  - docs/**/*.md
  - gitops/**
  - scripts/**
  - .agents/skills/ocp-*/**
---

# OpenShift Platform

Use the `ocp-*` skills as the source of truth for OpenShift Container Platform
infrastructure, control plane, networking, authentication, monitoring, GitOps,
and cluster integration guidance. Skills will be created as stages are
implemented.

Official Red Hat documentation for the active OCP baseline in
`docs/PLATFORM_BASELINE.md` is product authority. Do not invent OpenShift API
fields, unsupported operator settings, or cluster configuration assumptions.

For live `oc` or `kubectl` commands, follow the OpenShift safety guard in
`AGENTS.md` and pair OCP skills with the relevant `env-*` skill. Treat etcd,
control plane, MachineConfig, and cluster-wide authentication changes as
high-risk operations that require explicit user approval and official docs.

OLM-generated CSVs, copied CSVs, CSV `relatedImages`, operator deployments,
and operator-generated operands are operator-owned state. Do not copy them into
GitOps or patch their image fields as a normal compatibility path. For
operator compatibility, inspect the Subscription `status.installedCSV`, the
owning CSV, CRDs, events, and user-facing readiness, then update Git-managed
Subscription lifecycle policy or the product baseline.
