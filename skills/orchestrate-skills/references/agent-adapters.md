# Agent Adapter Notes

Use this reference only when adapting `orchestrate-skills` to another agent tool or explaining portability.

## Canonical Contract

- Keep `skills/orchestrate-skills/SKILL.md` as the source of truth.
- Adapters should be short pointers, not forks of the full workflow.
- Prefer one active Skill inventory root per agent session, then allow explicit extra roots.
- Never hardcode personal absolute paths in adapters, READMEs, or generated inventory.

## Agent Targets

| Agent/tool | Native surface | Recommended adapter |
|---|---|---|
| Codex | `~/.codex/skills/<name>/SKILL.md` | Copy the skill folder into the Codex Skills root. |
| Claude Code | `~/.claude/skills/<name>/SKILL.md`, project `.claude/skills/` | Copy the same skill folder; Claude can model-invoke it from the description. |
| Cursor | `.cursor/rules/*.mdc` | Add a short rule that points to this `SKILL.md` and asks the agent to propose the pipeline before editing. |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md` | Add repo instructions that point to this Skill when tasks require skill routing or planning. |
| OpenHands / Cline / Continue / Windsurf / other agents | Tool-specific rules or shared repo instructions | Prefer `AGENTS.md` plus a tool-specific short rule if supported. |

## Adapter Behavior

An adapter should tell the host agent to:

1. Restate task intent.
2. Scan or list locally available Skills/instructions.
3. Read only shortlisted `SKILL.md` files.
4. Propose a pipeline with confidence and validation.
5. Wait for explicit confirmation before substantial changes.
6. Track the work as a concrete goal when the host tool supports goals/tasks.

## Portability Limits

- Some agents do not support model-invoked Skills; they need always-on instructions or rules.
- Some agents cannot run the inventory scanner directly; in that case, use filesystem search over `SKILL.md` frontmatter.
- Copilot instructions are repository-scoped, so they should describe the workflow and reference the canonical Skill path rather than attempt to install it globally.
- Cursor rules are project-scoped and may not execute scripts automatically; keep the rule focused on planning behavior and explicit user confirmation.
