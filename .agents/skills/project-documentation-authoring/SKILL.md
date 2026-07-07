---
name: project-documentation-authoring
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# Documentation Authoring

## Purpose

Conventions for writing stage READMEs and project documentation.

## Stage README Structure

```markdown
# Stage YXX: Stage Title

## Why

Business value and enterprise context for this capability.

## What

Technical components introduced in this stage:
- Component A — brief description
- Component B — brief description

## Architecture

Description of the architecture delta from the previous stage.

## Official Documentation

- [Component A docs](https://...)
- [Component B docs](https://...)

## Prerequisites

- Stage N-1 deployed and validated
```

## Rules

- READMEs provide Why/What, not How (that's in GitOps and scripts)
- Link to official Red Hat and NVIDIA documentation
- Do not claim unimplemented capabilities
- Label future/deferred items clearly
- Keep operational details in `docs/OPERATIONS.md`
- Keep failure recovery in `docs/TROUBLESHOOTING.md`
