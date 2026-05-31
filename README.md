# Codex Skills 管理索引

这个目录用于管理和审计本机可用的 Skills。默认只纳入 Codex 当前会加载的全局 Skills：

- `$HOME\.codex\skills`：Codex 当前会加载的全局 Skills，包含 `.system` 下的系统 Skills。

其他 repo-local 或上游源目录可以在刷新清单时通过参数显式传入，不应把个人电脑上的绝对路径提交到仓库。

新增的 `orchestrate-skills` 是入口调度 Skill：适合在任务较宽、较模糊或跨多个阶段时先做意图识别、扫描本地已安装 Skills、形成 pipeline，并在用户确认后创建 goal 执行。它自带轻量扫描脚本，只读取 `SKILL.md` frontmatter，避免一次性加载所有 Skill 正文。

## 开源 Skill

可开源的源目录在：

- `skills\orchestrate-skills`

安装到本机 Codex：

```powershell
Copy-Item -Recurse -Force .\skills\orchestrate-skills "$HOME\.codex\skills\orchestrate-skills"
```

运行轻量候选扫描：

```powershell
python .\skills\orchestrate-skills\scripts\scan_installed_skills.py --query "帮我写论文并编译 PDF" --top 10
```

运行测试：

```powershell
python -m unittest discover -s tests
```

开源时不要提交 `generated\` 或 `skills\**\generated\`，这些是本机扫描缓存。

## 刷新清单

```powershell
.\scripts\Export-SkillInventory.ps1
```

如需同时纳入其他 Skill 根目录：

```powershell
.\scripts\Export-SkillInventory.ps1 -ExtraSkillsRoots "D:\path\to\repo\.agents\skills", "D:\path\to\gsap\skills"
```

输出文件：

- `generated\skills-inventory.md`：按来源、类别、重复项和完整清单生成的人类可读报告。
- `generated\skills-inventory.json`：结构化清单，便于后续做筛选、去重或同步脚本。

## 管理原则

- 把 `$HOME\.codex\skills` 当作运行时目录：只有真正想让 Codex 全局触发的 Skills 才放这里。
- 把 repo-local Skills 留在对应项目里：这类 Skills 往往绑定特定代码库，不建议直接混入全局，除非明确希望跨仓库复用。
- 把上游源目录作为刷新来源：需要同步第三方 Skills 时，先更新上游仓库，再同步到 `.codex\skills`。
- 把 `orchestrate-skills` 当作任务入口：复杂任务先让它给出 pipeline，确认后再进入 goal 执行。
- `.system` 目录保留给 Codex 系统 Skills，不手动改名或删除。
