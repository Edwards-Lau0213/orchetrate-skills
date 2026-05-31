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
