# Agent Instructions

This repository publishes `orchestrate-skills`, a portable Skill for turning broad user tasks into confirmed Skill pipelines and goal-driven execution.

When an agent works in this repository:

- Treat `skills/orchestrate-skills/SKILL.md` as the canonical instructions.
- Do not duplicate the full Skill body into tool-specific instruction files.
- Use adapter files only to point Claude Code, Cursor, GitHub Copilot, Codex, and similar agents back to the canonical Skill.
- Do not commit generated inventories, local caches, or personal absolute paths.
- Validate changes with `python -m unittest discover -s tests`.

For tasks about Skill routing, Skill inventory, pipeline planning, goal creation, or cross-agent portability, read `skills/orchestrate-skills/SKILL.md` first, then read `skills/orchestrate-skills/references/agent-adapters.md` only if adapter behavior is relevant.
