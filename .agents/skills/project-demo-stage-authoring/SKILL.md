---
name: project-demo-stage-authoring
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# Demo Stage Authoring

## Purpose

Phase-gate process for creating new demo stages in this repository.

## Stage Authoring Phases

### Phase 1: Intent and Planning

1. Define the stage's business value and technical scope
2. Create `stage-YXX-slug/PLAN.md` with acceptance criteria
3. Identify required RHOAI/NVIDIA components and skills

### Phase 2: Documentation

1. Write `stage-YXX-slug/README.md` (Why/What narrative)
2. Link to official Red Hat and NVIDIA documentation
3. Show the architecture delta from the previous stage

### Phase 3: GitOps Manifests

1. Create `gitops/stage-YXX-slug/` Kustomize structure
2. Create `gitops/argocd/app-of-apps/stage-YXX-slug.yaml`
3. Follow the operator GitOps pattern for Red Hat operators

### Phase 4: Deploy and Validate Scripts

1. Create `stage-YXX-slug/deploy.sh` with cluster guard
2. Create `stage-YXX-slug/validate.sh` with health checks
3. Test end-to-end deployment

### Phase 5: Review

1. Verify README claims match implementation
2. Run `validate.sh` successfully
3. Update `docs/OPERATIONS.md` with deployment notes

## Stage Numbering

- `100-199`: Platform foundation
- `200-299`: Production GenAI & private data
- `300-399`: Agentic AI & multi-agent research
- `400-499`: MLOps & operations (future)
