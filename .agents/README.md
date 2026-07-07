# Agent Guidance

This directory contains tool-neutral shared agent guidance. It is the single
source of truth for rules, skills, hooks, and references — regardless of which
AI coding tool is used.

## Layout

| Path | Purpose |
|------|---------|
| `hooks/` | Shared hook implementations (cluster guard, YAML validation, docs consistency) |
| `rules/*.md` | Short tool-neutral domain rules |
| `skills/*/SKILL.md` | Canonical shared skills following the Agent Skills layout |

## Tool-Agnostic Design

All agent guidance lives here. Tool-specific configuration is minimized:

- **Cursor**: `.cursor/hooks.json` wires hooks from `.agents/hooks/`. This is
  the only tracked tool-specific file because Cursor requires this path.
- **Claude Code**: Reads `AGENTS.md` at the repo root natively.
- **Codex**: Reads `AGENTS.md` and discovers `.agents/skills/` natively.
- **Other tools**: Point to `AGENTS.md` and `.agents/` as needed.

No tool-specific rules, skills, or duplicated guidance should exist outside
this directory. If a tool requires a bridge file, keep it minimal and point
back here.
