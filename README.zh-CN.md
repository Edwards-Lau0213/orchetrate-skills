# Orchestrate Skills

简体中文 | [English](README.md)

把宽泛的 Agent 任务转成可确认的 Skill pipeline，再作为明确 goal 执行。

`orchestrate-skills` 是一个面向多 Agent 工具的便携 Skill。它会扫描本地可用的 `SKILL.md` 元数据，选择最小且有用的 Skill 组合，形成 pipeline，等待用户确认，然后把任务推进到可验证的执行目标。

## 为什么需要它

当本地 Skills 越来越多时，真正麻烦的不是写某一个 Skill，而是每次任务开始前判断该用哪些 Skill、按什么顺序用，以及如何避免把所有 Skill 正文一次性塞进上下文。

这个 Skill 提供：

- **实时清单**：每次使用前扫描当前已安装 Skills。
- **低成本路由**：先读取 `SKILL.md` frontmatter，再决定是否读取完整正文。
- **Pipeline 规划**：把任务拆成 discover、plan、implement、verify、review、ship 等阶段。
- **用户确认**：在正式执行或产生副作用前先等用户确认。
- **Goal 衔接**：把确认后的 pipeline 转成具体、可验证的执行目标。
- **跨 Agent 适配**：保留一个 canonical Skill，再用轻量 adapter 支持 Codex、Claude Code、Cursor、GitHub Copilot 等工具。

## 仓库结构

```text
.
├── skills/orchestrate-skills/          # canonical Skill 包
│   ├── SKILL.md                        # 主工作流和触发 description
│   ├── agents/openai.yaml              # Codex/OpenAI UI 元数据
│   ├── references/                     # 仅在需要时加载的参考资料
│   └── scripts/scan_installed_skills.py
├── AGENTS.md                           # 跨 Agent 仓库约定
├── CLAUDE.md                           # Claude Code adapter 说明
├── .cursor/rules/orchestrate-skills.mdc
├── .github/copilot-instructions.md
├── docs/examples/
├── scripts/Export-SkillInventory.ps1
└── tests/
```

## 支持的 Agent 工具

| 工具 | 支持方式 | 使用方式 |
|---|---|---|
| Codex | 原生 Skill 目录 | 复制 `skills/orchestrate-skills` 到 `$HOME/.codex/skills/orchestrate-skills`。 |
| Claude Code | 原生 Skill 目录 | 复制同一目录到 `$HOME/.claude/skills/orchestrate-skills` 或项目内 `.claude/skills/orchestrate-skills`。 |
| Cursor | Rule adapter | 使用 `.cursor/rules/orchestrate-skills.mdc` 指回 canonical Skill。 |
| GitHub Copilot | 仓库级 instructions | 使用 `.github/copilot-instructions.md` 和 `AGENTS.md`。 |
| OpenHands、Cline、Continue、Windsurf 等 | 通用 adapter | 使用 `AGENTS.md` 加上对应工具自己的 rule/instruction 机制。 |

核心原则：**一个 canonical Skill，多个轻量 adapter**。

## 安装

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

把 `.cursor/rules/orchestrate-skills.mdc` 保留在目标仓库中，或复制到其他需要使用该工作流的仓库。

### GitHub Copilot

把 `.github/copilot-instructions.md` 和 `AGENTS.md` 保留在仓库中。Copilot 在该仓库工作时会读取这些仓库级说明。

### 脚本安装

安装到 Codex 和 Claude Code，并把项目 adapter 复制到当前仓库：

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets All -ProjectRoot .
```

只安装某个目标：

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets Codex
.\scripts\Install-AgentAdapters.ps1 -Targets Claude
.\scripts\Install-AgentAdapters.ps1 -Targets ProjectAdapters -ProjectRoot <path-to-repo>
```

项目 adapter 默认不会覆盖已有文件；需要覆盖时添加 `-Force`。

常用安全模式：

```powershell
.\scripts\Install-AgentAdapters.ps1 -Targets All -DryRun
.\scripts\Install-AgentAdapters.ps1 -Targets All -Check
.\scripts\Install-AgentAdapters.ps1 -Targets Codex,Claude -Backup -Force
```

备份默认写到 Skill 根目录之外的 `$HOME/.codex/skill-backups`，避免 inventory 扫描把备份目录误认为已安装 Skill。需要自定义时可以传 `-BackupRoot`。

## 使用方式

向 Agent 提出一个宽泛任务：

```text
我想为公司设计一个主页。
```

期望流程：

1. 复述任务意图。
2. 扫描本地 Skill 元数据。
3. 选择候选 Skills。
4. 生成包含 confidence 和 validation 的 pipeline。
5. 等待用户确认。
6. 在宿主 Agent 支持时创建或跟踪具体 goal。
7. 执行并验证结果。

也可以直接测试扫描器：

```powershell
python .\skills\orchestrate-skills\scripts\scan_installed_skills.py --query "帮我设计公司主页" --top 10
```

## 快速示例

下面这些示例可以直接复制给 Agent。实际 pipeline 仍然以当前机器扫描到的本地 Skill inventory 为准。

### 示例 1：公司主页

```text
我要为公司设计一个主页。
```

可能形成的 pipeline：`Base Codex` 做需求和项目结构识别 -> `build-web-apps:frontend-app-builder` 规划页面结构和组件 -> `Base Codex` 实现页面 -> `qa` 或浏览器检查做响应式和渲染验证。

Goal objective：

```text
Build a company homepage in the current project and verify it with browser checks.
```

### 示例 2：优化一个 Skill

```text
继续优化 orchestrate-skills，让它更适合开源和跨 Agent 使用。
```

可能形成的 pipeline：`orchestrate-skills` 做 inventory 和任务路由 -> `skill-creator` 检查 Skill 结构、description、progressive disclosure 和验证方式 -> `Base Codex` 修改文档、脚本或 references -> 用 `quick_validate`、单元测试、scanner smoke test 和敏感路径扫描验证。

Goal objective：

```text
Update orchestrate-skills for cross-agent portability, validate the skill, and run repository tests.
```

### 示例 3：发布到 GitHub

```text
把这个 Skill 仓库推送到 GitHub。
```

可能形成的 pipeline：`Base Codex` 检查 git status、remote、branch 和忽略文件 -> 运行测试和敏感路径扫描 -> GitHub workflow 执行 stage、commit、push -> 验证远端分支和 commit。

Goal objective：

```text
Publish the intended Skill repository changes to GitHub and verify the remote branch.
```

### 示例 4：小红书图文

```text
帮我生成小红书图文，介绍这个 Skill 的痛点和好处。
```

可能形成的 pipeline：`Base Codex` 从 README 和 `SKILL.md` 提炼产品事实 -> 规划封面、痛点、机制、收益和 CTA -> `imagegen` 生成轮播图 -> 检查文案、标签、图片路径和发布完整性。

Goal objective：

```text
Create a Xiaohongshu carousel package with images, captions, body copy, tags, and verified output paths.
```

### 示例 5：抖音短视频

```text
生成一个中文抖音推广视频，前 3 秒吸引观众，带中文字幕。
```

可能形成的 pipeline：`Base Codex` 提炼卖点和黄金 3 秒 hook -> `hyperframes` 规划竖屏叙事、字幕节奏和视觉风格 -> `hyperframes-cli` 渲染视频 -> 检查字幕、抽帧、码率和 MP4 输出。

Goal objective：

```text
Render a vertical Douyin promo video with Chinese captions, a strong opening hook, and verified high-bitrate MP4 output.
```

更完整的中文示例见：[docs/examples/pipeline-examples.zh-CN.md](docs/examples/pipeline-examples.zh-CN.md)。

## 刷新 Skill 清单

生成本地 inventory 报告：

```powershell
.\scripts\Export-SkillInventory.ps1
```

显式纳入额外 Skill 根目录：

```powershell
.\scripts\Export-SkillInventory.ps1 -ExtraSkillsRoots "<path-to-repo>\.agents\skills", "<path-to-third-party-skills>"
```

生成文件会放在 `generated*/` 下，并被 Git 忽略。

## 设计原则

这个仓库遵循适合开源 Agent 工具的文档结构：快速说明价值、给出安装方式、提供具体示例、说明兼容矩阵，并保留验证命令。Skill 本身遵循 progressive disclosure：

- frontmatter description 决定 Skill 何时触发。
- `SKILL.md` 只保留核心工作流。
- `references/` 保存可选细节，仅在需要时读取。
- `scripts/` 负责确定性的 inventory 扫描。

## 验证

```powershell
python -m unittest discover -s tests
```

发布前建议扫描本机路径或敏感信息：

```powershell
rg -n "<local-path-or-secret-pattern>" .
```

## License

MIT.
