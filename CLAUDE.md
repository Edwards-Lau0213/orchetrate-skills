# Claude Code Notes

Use `skills/orchestrate-skills/SKILL.md` as the canonical Skill.

For personal Claude Code use, install it with:

```bash
mkdir -p ~/.claude/skills
cp -R skills/orchestrate-skills ~/.claude/skills/orchestrate-skills
```

For project-local use, copy it to:

```text
.claude/skills/orchestrate-skills/SKILL.md
```

When a user asks for broad task planning, Skill routing, goal formation, or agent portability, load the Skill and follow its pipeline confirmation workflow before making substantial changes.
