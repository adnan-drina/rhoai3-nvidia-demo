---
name: project-structure
metadata:
  version: 1.0.0
  platform-family: project
  platform-baseline: "repo"
  ocp-baseline: "repo"
  skill-group: "Project Structure"
---

# Project Structure

## Purpose

Defines the canonical repository layout for the RHOAI NVIDIA multi-agent
research demo.

## Repository Layout

```text
rhoai3-nvidia-demo/
├── AGENTS.md                     # Top-level agent instructions
├── README.md                     # Project overview
├── env.example                   # Environment template
├── .gitignore
├── .agents/                      # Shared agent guidance (tool-neutral)
│   ├── hooks/                    # Shared hook implementations
│   ├── rules/*.md                # Domain rules
│   ├── skills/*/SKILL.md         # Canonical skills
│   └── references/               # Reference maps and indexes
├── .cursor/                      # Cursor-specific hooks
├── .codex/                       # Codex-specific hooks
├── .claude/                      # Claude Code bridge
├── docs/                         # Promoted project documentation
│   ├── PLATFORM_BASELINE.md      # Product version baseline
│   ├── OPERATIONS.md             # Deployment and day-2 operations
│   ├── TROUBLESHOOTING.md        # Diagnostics and recovery
│   └── BACKLOG.md                # Active backlog
├── scripts/                      # Shared project automation
├── gitops/                       # Active GitOps source tree
│   ├── bootstrap/                # ArgoCD bootstrap
│   ├── argocd/app-of-apps/       # ArgoCD Application manifests
│   └── stage-YXX-slug/           # Per-stage Kustomize manifests
└── stage-YXX-slug/               # Per-stage docs + scripts
    ├── README.md                 # Why/What narrative
    ├── PLAN.md                   # Implementation plan
    ├── deploy.sh                 # Deployment script
    └── validate.sh               # Validation script
```

## Stage Numbering

| Range | Category |
|-------|----------|
| 100-199 | Platform Foundation (GitOps, RHOAI, GPU, storage) |
| 200-299 | Production GenAI (model serving, MaaS, RAG) |
| 300-399 | Agentic AI & Multi-Agent Research (NIM, orchestration, evaluation) |
| 400-499 | MLOps & Operations (reserved for future) |

## Dual-Tree Convention

Each stage exists in two places:
- `stage-YXX-slug/` — human docs, deploy/validate scripts
- `gitops/stage-YXX-slug/` — Kustomize manifests for ArgoCD
