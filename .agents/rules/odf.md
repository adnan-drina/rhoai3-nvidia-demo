---
name: odf
skill-group: OpenShift Data Foundation
skill-prefix: odf-
applies-to:
  - "docs/PLATFORM_BASELINE.md"
  - "docs/**/*.md"
  - "gitops/**/*.yaml"
  - "gitops/**/*.yml"
  - "scripts/**/*"
  - ".agents/skills/odf-*/**"
---

# ODF Guidance

Use this rule for OpenShift Data Foundation storage guidance. Keep detailed
procedures in `odf-*` skills and use official ODF documentation for the active
version in `docs/PLATFORM_BASELINE.md`.

## Source Rules

- Use ODF documentation from the pinned baseline, currently ODF 4.20.
- Do not use a newer ODF documentation version for product configuration unless
  `docs/PLATFORM_BASELINE.md` is updated first.
- Do not invent StorageCluster, NooBaa, BackingStore, BucketClass, OBC,
  StorageClass, or Ceph fields. Use official docs plus `oc explain` or CRD
  checks when a field is unclear.

## Demo Storage Posture

- Start with the minimum ODF footprint needed for the RHOAI demo:
  standalone Multicloud Object Gateway, NooBaa, and ObjectBucketClaims.
- Manage ODF Operator lifecycle through GitOps: keep the Subscription channel
  and approval strategy in Git.
- Treat generated OBC Secrets as credentials. Never commit generated bucket
  credentials.
- Live `oc` or `kubectl` commands that inspect or mutate the cluster must
  follow the OpenShift safety guard in `AGENTS.md`.
