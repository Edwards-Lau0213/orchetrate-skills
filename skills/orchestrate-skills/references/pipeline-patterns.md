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
