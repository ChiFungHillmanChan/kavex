# 常见问题

## 为什么用 bash 编排而不是基于 prompt 的自编排？

基于 prompt 的执行依赖 Claude 自觉遵守指令，但 prompt 合规是可以被跳过的 — Claude 可能会自行决定跳过验证或审查阶段。使用 bash 编排时，`kavex-loop.sh` 会在 Claude 退出 session 之后才运行验证。因为 Claude 已经退出，它无法跳过验证步骤。Bash 是老板，Claude 是执行者。

## 支持哪些语言和技术栈？

Kavex 支持 **Node.js、Python、Go、Rust、Ruby、Java 和 .NET**。技术栈由 `detect-stack.sh` 自动检测，它会查找项目中的特征文件（例如 Node.js 的 `package.json`、Rust 的 `Cargo.toml`、Go 的 `go.mod`）。验证门和自动格式化工具会根据检测到的技术栈自动使用正确的工具。

## `kavex` 和 `kavex-full` 两个插件有什么区别？

| 插件 | 包含内容 |
|------|---------|
| **kavex** | Slash 命令（`/plan`、`/verify-app`、`/code-review` 等）+ 工程协议技能 |
| **kavex-full** | `kavex` 的全部内容，加上安全钩子、验证门、自动格式化、commit 门和 Team Loop |

如果你只需要工作流命令而不需要强制执行，选择 `kavex`。如果你需要完整的自主工程系统和 bash 编排钩子，选择 `kavex-full`。

## Kavex 和 Ralph 相比有什么区别？

[Ralph](https://github.com/frankbria/ralph-claude-code) 启发了 bash 编排器模式 — 即由 bash 控制循环而不是依赖 prompt。Kavex 在此基础上增加了：7 层验证门、卡住循环的断路器、多模型审查（Claude + 可选的 Codex）、保存在 `.kavex-loop/` 中的可恢复状态、速率限制，以及 tmux 监控面板。

## Kavex 可以和 OpenAI Codex 一起使用吗？

Codex 集成是**可选的**。如果你安装了 `@openai/codex`，Kavex 可以使用 `codex-assist.sh` 进行跨模型代码审查 — 由不同的模型提供第二意见。这不是核心功能的必要条件。Kavex 仅使用 Claude Code 即可完整运行。

## 如果没有安装 `jq` 会怎样？

钩子会**为了安全而阻止操作**（fail-closed 设计）。Kavex 不会在缺少正确 JSON 解析的情况下静默放行可能危险的操作，而是会拒绝继续执行。安装 `jq` 即可解决：`brew install jq`（macOS）、`apt install jq`（Debian/Ubuntu）或 `dnf install jq`（Fedora）。

## 钩子可以被绕过吗？

可以，这是设计上的决定。用户始终拥有控制权。你可以通过 `kavex deactivate` 停用钩子，或者编辑 `settings.json` 移除钩子条目。Kavex 在活跃 session 期间执行纪律 — 它不会把你锁在自己的工具之外。要重新启用，运行 `kavex activate`。

## 如何添加新语言的支持？

1. 编辑 `detect-stack.sh`，添加你语言的检测逻辑（例如检查 Elixir 的 `mix.exs` 特征文件）。
2. 编辑 `verify-gate.sh`，添加该语言对应的 build、test、lint 和 typecheck 命令。
3. 可选：如果你的语言有标准格式化工具，更新自动格式化钩子。

## Kavex 在生产环境中使用安全吗？

Kavex 是一个**纯开发阶段工具**。钩子仅在 Claude Code session 内运行 — 不会在 CI/CD 流程、生产部署或 Claude Code 以外的任何环境中执行。Kavex 为你的开发工作流提供仪表化，不会触及你的生产系统。

## 如何停用特定钩子而不是全部停用？

编辑 `hooks.json` 或项目的 `settings.json`，移除或注释掉特定的钩子条目。例如，你可以保持 commit 门启用的同时停用 stop 钩子，或者反过来。之后运行 `kavex status` 确认哪些钩子仍然是启用的。

## Stop 钩子和 Team Loop 有什么区别？

**Stop 钩子**（`verify-on-stop.sh`）是一个快速门，每次 Claude 停止时运行 **lint + typecheck**。它可以快速捕获基本错误。**Team Loop**（`kavex-loop.sh`）是完整的自主工作流，为每个 PRD 项目运行 **7 层验证**（build、test、lint、typecheck、security 等），加上代码审查和自动 commit。Stop 钩子是安全网；Team Loop 是完整的工程流程。

## Team Loop 中断后可以恢复吗？

可以。Team Loop 会将状态保存在 `.kavex-loop/` 目录中，包括哪些 PRD 项目已完成、验证结果和审查状态。如果循环被中断（例如崩溃、网络问题或手动停止），只需重新运行相同的 `/kavex:loop` 命令。它会从上次中断的地方继续。
