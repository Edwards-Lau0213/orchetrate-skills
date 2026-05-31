# Pipeline Patterns

Use these as starting points only. Keep the final pipeline grounded in the installed Skill inventory.

## Research Paper

For a broad paper-writing task:

1. `[discover]` `research-lit` or `arxiv` - gather related work or source papers.
2. `[plan]` `paper-plan` - form the outline.
3. `[implement]` `paper-write` or `paper-writing` - draft the paper.
4. `[implement]` `paper-figure` / `figure-spec` / `mermaid-diagram` - create required figures.
5. `[verify]` `paper-compile` - compile and verify the PDF.
6. `[review]` `citation-audit` or `paper-claim-audit` - check claims and references before finalizing.

Prefer `paper-writing` when the user asks for an end-to-end paper pipeline.

## Patent

For patent drafting or patentability work:

1. `[discover]` `prior-art-search` - search prior art.
2. `[review]` `patent-novelty-check` - evaluate novelty and non-obviousness.
3. `[implement]` `patent-pipeline` - draft the complete application.
4. `[verify]` `patent-review` - get examiner-style critique.

Use `claims-drafting` or `specification-writing` for single-stage requests.

## Experiment

For ML or research experiments:

1. `[plan]` `experiment-plan` - produce evaluation and ablation plan.
2. `[implement]` `run-experiment` or `experiment-queue` - launch jobs.
3. `[verify]` `monitor-experiment` or `training-check` - track progress.
4. `[review]` `analyze-results` - summarize metrics and comparisons.
5. `[review]` `result-to-claim` and `experiment-audit` - decide supported claims.

Use `experiment-queue` when the task has many seeds/configs.

## Frontend And Animation

For frontend apps with animation:

1. `[implement]` Base frontend builder or existing repo conventions - implement the app.
2. `[implement]` `gsap-react`, `gsap-scrolltrigger`, `gsap-timeline`, or `gsap-core` - add animation.
3. `[review]` `gsap-performance` - optimize when smoothness or scroll jank matters.
4. `[verify]` `qa` or `qa-only` - verify the result in browser.

Choose the GSAP Skill by framework and animation type.

## Skill Authoring

For creating or maintaining Skills:

1. `[plan]` `orchestrate-skills` - route broad skill-management tasks.
2. `[implement]` `skill-creator` - follow Codex Skill structure and validation.
3. `[implement]` `skill-installer` - install from curated sources or GitHub when needed.
4. `[verify]` `skill-creator` validation scripts or available tests - prove the Skill is valid.

Always validate a Skill before calling it complete.

## Skill Optimization

For improving an existing Skill:

1. `[discover]` `orchestrate-skills` - scan the current inventory and classify whether the task is trigger, routing, docs, adapter, script, or validation work.
2. `[plan]` `skill-creator` - preserve progressive disclosure: frontmatter for triggering, `SKILL.md` for core workflow, references for optional details, scripts for deterministic behavior.
3. `[implement]` Base Codex - update only the canonical Skill and supporting resources.
4. `[verify]` `skill-creator` validation plus repo tests - run quick validation, unit tests, scanner smoke tests, and sensitive-path scans.

Prefer adding examples and tests over adding long prose to `SKILL.md`.

## Debug Or Fix

For debugging code, tests, CI, or local tools:

1. `[discover]` Base Codex or debugging Skill - reproduce the issue and capture the failing command/output.
2. `[plan]` `systematic-debugging` or Base Codex - identify the smallest likely failure boundary.
3. `[implement]` Base Codex - patch the root cause without unrelated refactors.
4. `[verify]` Relevant tests or commands - prove the original failure is fixed.
5. `[review]` `review` when the patch affects shared behavior or user-facing workflows.

Use this pattern when the task says "报错", "失败", "fix", "debug", "CI", or "测试不过".

## GitHub Publish

For publishing local changes:

1. `[discover]` GitHub workflow or Base Codex - inspect branch, status, remote, and diff scope.
2. `[verify]` Base Codex - run relevant checks before committing.
3. `[ship]` GitHub publish flow - stage only intended files, commit, push, and open PR when requested.
4. `[verify]` Base Codex - confirm remote branch/commit and report blockers such as auth or missing remote.

Never stage generated artifacts or unrelated user files silently.

## Content And Video

For social posts, launch notes, video scripts, or marketing assets:

1. `[discover]` Base Codex - extract product facts from README, docs, or source files.
2. `[plan]` Base Codex - choose audience, hook, narrative arc, deliverables, and validation criteria.
3. `[implement]` `imagegen`, `hyperframes`, or Base Codex - create visuals, scripts, captions, or video assets as requested.
4. `[verify]` QA/render checks - inspect generated images/video, check text readability, and confirm output paths/specs.

Use a final verify step even for content because visual text, aspect ratio, and file paths are frequent failure points.

## Cross-Agent Adapter

For adapting a Skill to Claude Code, Cursor, GitHub Copilot, OpenHands, Cline, Continue, Windsurf, or similar tools:

1. `[discover]` `orchestrate-skills` - identify the canonical Skill and target agent surfaces.
2. `[plan]` `skill-creator` - decide which details stay in `SKILL.md` and which become adapter pointers.
3. `[implement]` Base Codex - create or update `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*.mdc`, `.github/copilot-instructions.md`, or target-specific files.
4. `[verify]` Base Codex - run adapter install dry-run/check commands and scan for hardcoded personal paths.

Keep adapters short. They should point to the canonical Skill instead of copying it.
