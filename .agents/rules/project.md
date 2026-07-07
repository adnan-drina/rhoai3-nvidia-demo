---
name: project
skill-group: Project Structure
skill-prefix: project-
applies-to:
  - AGENTS.md
  - .agents/**
  - .claude/**
  - .codex/**
  - .cursor/**
  - .gitignore
  - README.md
  - "**/README.md"
  - docs/**/*.md
  - gitops/**
  - stage-*/**
  - scripts/**
---

# Project Structure

Use the `project-*` skills as the source of truth for work that changes the
repository, GitOps layout, stage content, documentation structure, manifest
standards, or shared agent guidance:

- `.agents/skills/project-structure/SKILL.md`
- `.agents/skills/project-agent-guidance/SKILL.md`
- `.agents/skills/project-demo-stage-authoring/SKILL.md`
- `.agents/skills/project-gitops-authoring/SKILL.md`
- `.agents/skills/project-documentation-authoring/SKILL.md`
- `.agents/skills/project-manifest-review/SKILL.md`
- `.agents/skills/project-architecture-diagrams/SKILL.md`

Keep the demo coherent as a multi-agent research story for enterprises using
Red Hat OpenShift AI and NVIDIA technologies. GitOps, stage READMEs,
operational docs, architecture diagrams, and agent guidance must stay aligned
with the active baseline in `docs/PLATFORM_BASELINE.md`.

New demo stages must be created as root-level `stage-YXX-slug/` folders.

Use `project-demo-stage-authoring` for every new demo stage. Start with intent,
source capture, skill routing, and `PLAN.md`; then author the README, GitOps,
Argo CD Application, manifests, deploy script, validation script, and review
evidence as one atomic stage. Do not let README claims, GitOps manifests, and
validation scripts drift apart.

Do not silently defer or remove components from an agreed stage scope. If a
component is too risky, blocked, or better suited for a later stage, pause and
discuss the tradeoff with the user before changing its status. Record the
accepted decision in the stage `PLAN.md` or `docs/BACKLOG.md`.

Stage READMEs should be concise Why/What documents: introduce the business
concept, map the concept to official Red Hat and NVIDIA product documentation,
and show the architecture delta. GitOps artifacts and live demos show the How.

Do not use this rule as the source of truth for specific RHOAI API fields or
live cluster operations. Use the `rhoai` or `env` rule and matching skills for
those domains.
