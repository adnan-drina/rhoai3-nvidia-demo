---
name: project-agent-guidance
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# Agent Guidance Governance

## Purpose

Governs the shared agent guidance system: rules, skills, hooks, references,
and tool-specific bridges.

## Guidance Architecture

```text
AGENTS.md (entry point)
  → .agents/rules/*.md (domain rules)
  → .agents/skills/*/SKILL.md (detailed skills)
  → .agents/references/ (reference maps)
  → .agents/hooks/ (shared hooks)
```

Tool-specific bridges:
- `.cursor/hooks.json` → calls shared hooks
- `.codex/hooks.json` → calls shared hooks
- `.claude/CLAUDE.md` → references AGENTS.md

## Skill Groups

| Group | Prefix | Purpose |
|-------|--------|---------|
| Project Structure | `project-*` | Repo layout, stages, GitOps, docs, guidance |
| Demo Environment | `env-*` | Live cluster deployment and operations |
| RHOAI Platform | `rhoai-*` | RHOAI component guidance |
| OpenShift Platform | `ocp-*` | OCP infrastructure guidance |
| OpenShift Data Foundation | `odf-*` | ODF storage guidance |
| NVIDIA Integration | `nvidia-*` | NVIDIA NIM, NeMo, agents |
| Assets & Miscellaneous | `assets-*` | Visual and presentation assets |

## Skill Frontmatter

Every skill must include:

```yaml
---
name: <skill-name>
metadata:
  version: 1.0.0
  platform-family: <rhoai|ocp|odf|nvidia|project|env|assets>
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "<one of the seven groups>"
---
```

## Inventory

| Category | Count |
|----------|-------|
| Shared skills | 14 |
