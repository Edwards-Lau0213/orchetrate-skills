---
name: orchestrate-skills
description: Use when the user gives a broad, multi-step, ambiguous, cross-domain, or high-stakes task and wants an agent to inspect available local Skills/instructions, choose the smallest useful set, form a confirmed execution pipeline, create or translate the task into an explicit goal, and keep working until completion. Also use for Skill inventory management, intent routing, task routing, pipeline planning, goal formation, rules/instructions management, AGENTS.md/CLAUDE.md/Cursor rules/Copilot instructions adapters, or multi-agent Skill portability across Codex, Claude Code, Cursor, GitHub Copilot, OpenHands, Cline, Continue, Windsurf, and similar coding-agent tools.
---

# Orchestrate Skills

## Overview

Turn an open-ended request into a confirmed execution pipeline. Prefer local Skills and agent-native instruction files over memory or generic reasoning, then run the work under an explicit goal after user confirmation.

This Skill is the canonical workflow. Other agents may reach it through thin adapters such as `AGENTS.md`, `CLAUDE.md`, Cursor rules, or Copilot instructions; those adapters should point back here rather than duplicate the full workflow.

## Workflow

1. Restate the task intent in one sentence.
2. Identify task type, likely deliverables, constraints, and risks.
3. Refresh the local Skill inventory before proposing execution:
   - Run this skill's `scripts/scan_installed_skills.py` against the active agent's Skill root.
   - For Codex, default to `~/.codex/skills`; for Claude Code, default to `~/.claude/skills`; for project-local usage, prefer the nearest repo skill folder when the adapter defines one.
   - Pass the user task as `--query`, use `--top 25`, and write the full scan to `generated/latest-installed-skills.json`.
   - The scan reads only each `SKILL.md` frontmatter and uses `references/routing-aliases.json` for multilingual routing hints, so it stays cheap even with many Skills.
   - Treat `.system` Skills as authoring/runtime helpers, not ordinary workflow options unless the task is about skills, plugins, OpenAI docs, or image generation.
4. Select the smallest useful Skill set.
5. Read full `SKILL.md` bodies only for the shortlisted Skills that are likely to appear in the pipeline.
6. Form a pipeline with confidence, validation, and a concrete goal objective.
   - Explain routing evidence: include the top reasons for selected candidates and one short "not using" note for plausible alternatives.
   - If a mature pattern exists in `references/pipeline-patterns.md`, adapt it instead of inventing a new step order.
7. Ask for confirmation before starting substantial work.
8. After explicit user confirmation, create a goal if the goal tool is available, then execute the pipeline until the goal is complete or genuinely blocked.

## Inventory Refresh

Resolve the script relative to this Skill folder, then run:

```powershell
python .\scripts\scan_installed_skills.py --query "<user task>" --top 25 --format markdown --write-cache .\generated\latest-installed-skills.json
```

If the current working directory is not this Skill folder, use the absolute script path. On Windows, prefer `python`; if unavailable, try `py -3`. If the script cannot run, fall back to `rg --files -g SKILL.md ~/.codex/skills` plus frontmatter-only reads.

Use `--include-system` only when the task is about creating Skills, plugins, OpenAI docs, image generation, or Codex runtime behavior.

The scanner emits a `reason` column. Use it to explain candidate choices and to detect false positives before reading full Skill bodies.

By default, the scanner hides zero-score entries and downweights generic description hits such as `skills` or `user`. Use `--include-zero` only for diagnostics.

## Routing Resources

- `references/routing-aliases.json`: multilingual alias-to-Skill boost rules. Read or edit this when routing misses common user wording.
- `references/pipeline-patterns.md`: common pipeline skeletons for papers, patents, experiments, frontend animation, and Skill authoring. Use it only after inventory scan confirms the referenced Skills exist.
- `references/agent-adapters.md`: compatibility notes for Codex, Claude Code, Cursor, GitHub Copilot, and other agents. Read it only when the task asks about cross-agent installation, migration, adapter generation, or portability.

## Token Budget Rules

- Do not read every installed `SKILL.md` body.
- Use `name`, `description`, path, and score from the scan for first-pass routing.
- Use the scan `reason` field to justify why a candidate appears.
- Read a full Skill body only when it is a serious candidate or the pipeline step depends on its detailed workflow.
- Keep the shortlist normally to 3-7 Skills. For simple tasks, 0-2 Skills is fine.
- If several Skills overlap, prefer the most specific one and explain the discarded alternative only when it affects the plan.

## Pipeline Confidence

Assign one confidence level:

- **High**: top candidates have clear alias/name/description reasons, the task matches an available pipeline Skill or template, and validation is straightforward.
- **Medium**: relevant Skills exist, but step order or final deliverable requires inference.
- **Low**: no strong local Skill fits; the plan mostly uses base Codex or asks for missing context.

If confidence is Low, ask at most one clarifying question before proposing a risky pipeline.

## Pipeline Format

Use this compact format:

```markdown
**Intent**
<one sentence>

**Candidate Skills**
- `<skill-name>`: why it helps
- `<skill-name>`: why it helps

**Not Using**
- `<skill-name>`: why it is redundant or lower fit

**Pipeline**
1. `[discover|plan|implement|verify|review|ship]` `<skill-name or base Codex>` - concrete step and expected output
2. `[verify]` `<skill-name or base Codex>` - validation step and expected evidence

**Confidence**
High | Medium | Low - one sentence reason

**Goal Objective**
<concrete objective to pass to the goal tool after confirmation>

**Confirm**
Reply "确认执行" to create the goal and start. You can also say "只生成pipeline", "换一种pipeline", "不要用 <skill>", or "加入 <skill>".
```

For simple tasks, keep the pipeline short. For research, coding, documents, deployment, or frontend work, include validation as an explicit final step.

## Skill Selection Rules

- Prefer exact domain Skills over broad ones.
- Prefer pipeline Skills when the user asks for end-to-end work, for example `research-pipeline`, `paper-writing`, or `patent-pipeline`.
- Prefer narrow component Skills when the user asks for one stage, for example `arxiv`, `experiment-plan`, `paper-compile`, or `gsap-react`.
- Include process Skills only when they materially change execution, for example `review`, `qa`, `test-driven-development`, or `verification-before-completion`.
- If no local Skill fits, say so and use base Codex capabilities rather than forcing an irrelevant Skill.
- Do not include duplicate source copies in the same pipeline. If a Skill exists both in Codex installed and a desktop source repo, use the installed Codex copy.
- For non-Codex agents, preserve this Skill as the source of truth and create only a small adapter that explains where the canonical `SKILL.md` lives and how to invoke the pipeline confirmation workflow.
- If the task asks to manage agent rules or instructions rather than executable Skills, treat those files as instruction surfaces and still propose the same confirm-before-execute pipeline.

## Confirmation and Goal Rules

- Do not create a goal before the user confirms the pipeline.
- Treat "确认执行", "开始", "go", "run it", or an equivalent explicit approval as confirmation.
- Treat "只生成pipeline" as a request to stop after planning.
- Treat "换一种pipeline" as a request to rescan/re-rank and propose an alternative.
- Treat "不要用 <skill>" as a hard exclusion for the next proposal.
- Treat "加入 <skill>" as a forced candidate, but still explain risk if it does not fit.
- When confirmed, call the goal tool with the exact `Goal Objective` or a minimally refined version.
- Keep the goal active while executing. Update the user as work progresses.
- Mark the goal complete only when the requested deliverable is finished and verified.
- Mark blocked only when the same blocking condition repeats for the required goal-blocking threshold and no meaningful progress is possible without user input.

## Goal Objective Templates

Use a concrete, verifiable objective:

- Build/edit: `Complete <deliverable> in <location> and verify with <test/check>.`
- Debug/fix: `Fix <problem>, prove it with <reproduction/test>, and leave <artifact> updated.`
- Research/paper: `Produce <paper/report artifact> and verify <compile/citation/claim checks>.`
- Skill work: `Update <skill name> to support <capability>, validate the skill, and run its tests.`
- Agent adapter work: `Adapt <skill/workflow> for <agent tools>, preserve the canonical source, verify adapters, and document installation.`
- Analysis-only: `Analyze <subject> and deliver <summary/report> with evidence from <sources/files>.`

## Validation Gate

Every pipeline that changes files, code, documents, Skills, or user-facing output must include a final `verify` step. If no validation Skill fits, use base Codex with commands, rendering checks, tests, or manual artifact inspection. Do not mark the goal complete without reporting validation evidence.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Using stale memory of installed Skills | Run the inventory scan at the start of each use. |
| Reading every Skill body | Route from frontmatter first; read only shortlisted bodies. |
| Listing every possibly related Skill | Select the smallest set that changes execution. |
| Starting work before confirmation | Stop after the pipeline and wait. |
| Creating a goal for a vague objective | Rewrite it as a concrete deliverable first. |
| Omitting confidence or validation | Add confidence and a final verify step before asking for confirmation. |
| Treating desktop repo-local Skills as global | Use repo-local Skills only when working in that repo or when the user explicitly asks. |
| Forgetting validation | Add a final verification step before completion. |
