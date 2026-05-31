# Pipeline Examples

这些示例用于说明 `orchestrate-skills` 应该如何把宽泛任务转成可确认的 pipeline。示例是文档，不是固定输出模板；实际运行时仍以本地 inventory 扫描结果为准。

## 示例 1：公司主页

用户输入：

```text
我要为公司设计一个主页。
```

Pipeline:

1. `[discover]` Base Codex - 识别行业、目标用户、品牌信息和现有项目结构。
2. `[plan]` `build-web-apps:frontend-app-builder` - 规划页面信息架构和组件。
3. `[implement]` Base Codex - 实现主页。
4. `[verify]` `qa` 或 Base Codex - 浏览器检查、响应式截图、文本溢出检查。

Goal:

```text
Build a company homepage in the current project and verify it with browser checks.
```

## 示例 2：优化一个 Skill

用户输入：

```text
继续优化 orchestrate-skills，让它更适合开源和跨 Agent 使用。
```

Pipeline:

1. `[discover]` `orchestrate-skills` - 扫描本地 Skills 并确认任务属于 Skill 管理/adapter 工作。
2. `[plan]` `skill-creator` - 检查 description、progressive disclosure、scripts、references、agents metadata。
3. `[implement]` Base Codex - 更新 canonical Skill、aliases、pipeline patterns、README/docs。
4. `[verify]` `skill-creator` + Base Codex - quick_validate、unit tests、scanner smoke test、敏感路径扫描。

Goal:

```text
Update orchestrate-skills for cross-agent portability, validate the skill, and run repository tests.
```

## 示例 3：GitHub 发布

用户输入：

```text
把这个 Skill 推到 GitHub。
```

Pipeline:

1. `[discover]` Base Codex - 检查 git status、remote、branch、未跟踪文件。
2. `[verify]` Base Codex - 跑测试并确认没有敏感路径。
3. `[ship]` GitHub workflow - stage、commit、push。
4. `[verify]` Base Codex - 确认远端 commit 和 tracking 状态。

Goal:

```text
Publish the intended Skill repository changes to GitHub and verify the remote branch.
```

## 示例 4：小红书图文

用户输入：

```text
帮我生成小红书图文，介绍这个 Skill 的痛点和好处。
```

Pipeline:

1. `[discover]` Base Codex - 从 README 和 Skill 文件提炼产品事实。
2. `[plan]` Base Codex - 设计封面、痛点、机制、收益、CTA。
3. `[implement]` `imagegen` + Base Codex - 生成轮播图和可复制文案。
4. `[verify]` Base Codex - 检查文字准确性、图片路径、发布文案完整性。

Goal:

```text
Create a Xiaohongshu carousel package with images, captions, body copy, tags, and verified output paths.
```

## 示例 5：抖音短视频

用户输入：

```text
生成一个中文抖音推广视频，前 3 秒吸引观众，带中文字幕。
```

Pipeline:

1. `[discover]` Base Codex - 提炼产品卖点和目标观众。
2. `[plan]` `hyperframes` - 设计竖屏叙事、黄金 3 秒、字幕节奏和视觉风格。
3. `[implement]` `hyperframes` / `hyperframes-cli` - 生成 HTML composition、字幕、音频和视频。
4. `[verify]` `hyperframes-cli` + Base Codex - lint、validate、inspect、抽帧检查、码率检查。

Goal:

```text
Render a vertical Douyin promo video with Chinese captions, strong opening hook, and verified high-bitrate MP4 output.
```
