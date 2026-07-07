---
name: rhoai
skill-group: RHOAI Platform
skill-prefix: rhoai-
applies-to:
  - docs/PLATFORM_BASELINE.md
  - docs/rhoai-*/**
  - gitops/**
  - stage-*/**/*.py
  - stage-*/**/*.ipynb
---

# RHOAI Platform

Use the `rhoai-*` skills as the source of truth for RHOAI component behavior,
configuration, pipelines, and agent workflow integration. Skills will be created
as stages are implemented.

Official Red Hat documentation for the active baseline in
`docs/PLATFORM_BASELINE.md` is the product source of truth. Use Red Hat articles
only as supporting implementation evidence.

When a README introduces a RHOAI capability, pair the concept narrative with an
official documentation link for each technical component used. When a manifest
introduces images or model artifacts, verify Red Hat registry, validated model,
or explicitly documented demo-exception provenance before treating it as
aligned.

RHOAI controllers and prerequisite operators can generate product-owned
operands. Do not patch generated operand image fields, generated datasources, or
operator-created Deployments as durable fixes. Use the matching `rhoai-*`
skill to decide whether the fix belongs in `DataScienceCluster`/`DSCInitialization`
configuration, Subscription lifecycle policy, product baseline alignment, or a
documented product wait.

Do not invent CR fields, API versions, annotations, or operator settings. If a
field is uncertain, verify it through official docs or schema inspection.
