---
name: project-manifest-review
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# Manifest Review

## Purpose

Review checklist for GitOps manifests before they are merged.

## Review Checklist

1. **API version**: Uses the correct API version for the baseline OCP version
2. **Namespace**: Correct namespace for the stage
3. **Labels**: Consistent labeling scheme
4. **Image provenance**: Red Hat registry, validated model, or documented exception
5. **Operator ownership**: Does not patch operator-owned fields
6. **Kustomize**: `kustomize build` succeeds
7. **ArgoCD**: Application uses `project: rhoai-nvidia-demo`
8. **Secrets**: No credentials in manifests; created by deploy scripts
9. **Documentation alignment**: README matches what manifests deploy
