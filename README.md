# Orchestrate Skills

[简体中文](README.zh-CN.md) | English

Turn a broad agent task into a confirmed Skill pipeline, then execute it as a concrete goal.

`orchestrate-skills` is a portable Skill for agents that support local instructions, Skills, rules, or repository guidance. It scans available `SKILL.md` metadata, selects a small set of useful capabilities, proposes a pipeline, waits for user confirmation, and keeps validation explicit.

## Why This Exists

As local Skills grow, the hard part is no longer writing one Skill. The hard part is choosing the right combination without loading every file into context.

This Skill provides:

- **Fresh inventory**: scan installed Skills at the start of each use.
- **Cheap routing**: read only `SKILL.md` frontmatter before shortlisting.
- **Pipeline planning**: map tasks into discover, plan, implement, verify, review, and ship steps.
- **User confirmation**: wait before substantial work or side effects.
- **Goal handoff**: turn the confirmed pipeline into a concrete execution objective.
- **Agent portability**: keep one canonical Skill and add thin adapters for Codex, Claude Code, Cursor, GitHub Copilot, and similar tools.

## Repository Layout

```text
.
├── skills/orchestrate-skills/          # Canonical Skill package
│   ├── SKILL.md                        # Main workflow and trigger description
│   ├── agents/openai.yaml              # Codex/OpenAI UI metadata
│   ├── references/                     # Optional context loaded only when needed
│   └── scripts/scan_installed_skills.py
├── AGENTS.md                           # Cross-agent repository contract
├── CLAUDE.md                           # Claude Code adapter notes
├── .cursor/rules/orchestrate-skills.mdc
├── .github/copilot-instructions.md
├── docs/examples/
├── scripts/Export-SkillInventory.ps1
└── tests/
```

## Supported Agent Surfaces

| Tool | Support level | How to use |
|---|---|---|
| Codex | Native Skill folder | Copy `skills/orchestrate-skills` to `$HOME/.codex/skills/orchestrate-skills`. |
| Claude Code | Native Skill folder | Copy the same folder to `$HOME/.claude/skills/orchestrate-skills` or `.claude/skills/orchestrate-skills`. |
| Cursor | Rule adapter | Use `.cursor/rules/orchestrate-skills.mdc` to point Cursor back to the canonical Skill. |
| GitHub Copilot | Repository instructions | Use `.github/copilot-instructions.md` and `AGENTS.md` for repo-scoped behavior. |
| OpenHands, Cline, Continue, Windsurf, other agents | Generic adapter | Use `AGENTS.md` plus the host tool's rule/instruction surface. |

The guiding rule is simple: **one canonical Skill, many thin adapters**.

## Install

### Codex

```powershell
Copy-Item -Recurse -Force .\skills\orchestrate-skills "$HOME\.codex\skills\orchestrate-skills"
```

### Claude Code

```bash
mkdir -p ~/.claude/skills
cp -R skills/orchestrate-skills ~/.claude/skills/orchestrate-skills
```

### Cursor

Keep `.cursor/rules/orchestrate-skills.mdc` in the target repository, or copy it into another repository that should use this workflow.

### GitHub Copilot

Keep `.github/copilot-instructions.md` and `AGENTS.md` in the repository. Copilot will use repository instructions when working in that repo.

### Scripted Install

Install the Skill for Codex and Claude Code, and copy project adapters into the current repository:

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets All -ProjectRoot .
```

Install only one target:

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets Codex
.\scripts\Install-AgentAdapters.ps1 -Targets Claude
.\scripts\Install-AgentAdapters.ps1 -Targets ProjectAdapters -ProjectRoot <path-to-repo>
```

Project adapter files are not overwritten unless you add `-Force`.

Useful safety modes:

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets All -DryRun
.\scripts\Install-AgentAdapters.ps1 -Targets All -Check
.\scripts\Install-AgentAdapters.ps1 -Targets Codex,Claude -Backup -Force
```

Backups are written outside Skill roots by default under `$HOME/.codex/skill-backups` so inventory scans do not treat backups as installed Skills. Override with `-BackupRoot` if needed.

## Usage

Ask an agent something broad:

```text
I want to design a company homepage.
```

Expected behavior:

1. Restate intent.
2. Scan local Skill metadata.
3. Shortlist relevant Skills.
4. Propose a pipeline with confidence and validation.
5. Wait for confirmation.
6. Create or track a concrete goal when supported by the host agent.
7. Execute and verify.

You can also test the scanner directly:

```powershell
python .\skills\orchestrate-skills\scripts\scan_installed_skills.py --query "帮我设计公司主页" --top 10
```

## Refresh Inventory

Generate a local inventory report:

```powershell
.\scripts\Export-SkillInventory.ps1
```

Include additional Skill roots explicitly:

```powershell
.\scripts\Export-SkillInventory.ps1 -ExtraSkillsRoots "<path-to-repo>\.agents\skills", "<path-to-third-party-skills>"
```

Generated files go under `generated*/` and are ignored by Git.

## Design Notes

This README follows patterns common in popular agent projects: fast value statement, quick install, concrete usage, compatibility notes, examples, and validation commands. The Skill itself follows progressive disclosure:

- Frontmatter description decides when the Skill should trigger.
- `SKILL.md` contains only the core workflow.
- `references/` contains optional details for adapter and pipeline variants.
- `scripts/` handles deterministic inventory scanning.

See [docs/examples/pipeline-examples.zh-CN.md](docs/examples/pipeline-examples.zh-CN.md) for realistic Chinese task-to-pipeline examples.

## Validation

```powershell
python -m unittest discover -s tests
```

Before publishing, scan for local machine paths:

```powershell
rg -n "<local-path-or-secret-pattern>" .
```

## License

MIT.
