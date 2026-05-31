# Repository Instructions for GitHub Copilot

This repository contains a portable Skill named `orchestrate-skills`.

Use `skills/orchestrate-skills/SKILL.md` as the source of truth for tasks about:

- Skill inventory and routing
- Turning broad requests into confirmed pipelines
- Goal-oriented execution after user confirmation
- Cross-agent adapters for Codex, Claude Code, Cursor, GitHub Copilot, OpenHands, Cline, Continue, Windsurf, and similar tools

Do not duplicate the full Skill workflow into adapter files. Keep adapters short and point them back to the canonical Skill.

Before completing changes, run:

```powershell
python -m unittest discover -s tests
```

Do not commit generated inventories, local caches, credentials, or personal absolute paths.
