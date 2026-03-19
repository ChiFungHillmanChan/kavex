# Kova 架构文档

## 概述

Kova 是一个 **bash 强制执行的工程协议**，专为 Claude Code 设计。核心原则：

> **Claude 是干活的。Bash 是管事的。**

Claude Code 支持 hook 系统，可以在工具调用（文件写入、执行 bash 命令、停止事件）执行之前和之后进行拦截。Kova 通过 `hooks.json` 注册 hook，在这些拦截点执行 shell 脚本。因为 hook 运行在 Claude 的上下文之外——在独立的 bash 进程中执行——所以 Claude 无法跳过、修改或绕过验证。

这不是 prompt 工程。这是**流程强制执行**。

---

## Hook 执行流程

Claude Code 的 hook 系统会将工具调用的元数据以 JSON 格式通过 stdin 传递给 hook 脚本。每个 hook 脚本读取 JSON、检查内容，然后返回决定。

```
  Claude 调用工具 (Bash, Write, Edit, Stop)
         |
         v
  +------------------+
  |   hooks.json     |  Matcher 选择哪些 hook 需要触发
  |   (matcher)      |  例如 "Bash", "Write|Edit|MultiEdit", "Stop"
  +--------+---------+
           |
           v
  +------------------+
  | PreToolUse hook  |  在工具执行之前运行
  |  (stdin: JSON)   |
  +--------+---------+
           |
     +-----+------+
     |            |
   放行         拦截
     |         (exit 2，打印原因)
     v
  +------------------+
  |  工具执行         |
  +--------+---------+
           |
           v
  +------------------+
  | PostToolUse hook  |  在工具执行之后运行
  |  (例如 format.sh) |
  +------------------+
```

### 已注册的 Hook

```
PreToolUse:
  Bash           -> block-dangerous.sh    拦截 rm -rf /、DROP TABLE、force push 等
                 -> kova-commit-gate.sh   没有验证证明就拦截 git commit
  Write|Edit     -> protect-files.sh      拦截写入 .env、credentials 等敏感文件

PostToolUse:
  Write|Edit     -> format.sh            自动格式化写入的文件（Prettier、Ruff、gofmt 等）

Stop:
  (全部)          -> verify-on-stop.sh     快速门禁：Claude 停止前运行 lint + 类型检查
```

---

## 7 层验证

验证门禁（`verify-gate.sh`）最多运行 7 层检查。每一层会自动检测项目技术栈（Node.js、Python、Go、Rust、Ruby、Java、.NET）然后运行对应的工具。

```
  层次   检查               运行什么                          失败行为
  ----   ----------------   --------------------------------  --------
  [1]    构建 / 编译        npm run build、go build、          FAIL
                            cargo build、mvn compile 等
  [2]    单元测试            jest、vitest、pytest、go test、    FAIL
                            cargo test（带 flaky 重试）
  [3]    集成测试            npm run test:integration           FAIL
                            （带 flaky 重试）
  [4]    端到端测试          Playwright                         FAIL
                            （带 flaky 重试）
  [5]    Lint               eslint、ruff、clippy、              FAIL
                            golangci-lint、rubocop
  [6]    类型检查            tsc --noEmit、mypy、pyright、      FAIL
                            go vet、cargo check
  [7]    安全审计            npm audit、pip-audit、              仅警告
                            cargo audit、govulncheck
```

**Flaky 重试：** 第 2-4 层（测试层）失败时会自动重试一次再报告失败。这样可以处理间歇性的测试不稳定问题，但不会掩盖真正的错误。

**安全审计（第 7 层）：** 报告漏洞但不会导致门禁失败。这是有意设计——安全建议通常没有即时修复方案，不应该阻塞开发。

### 什么在哪里运行

| 场景             | 运行的层次  | 目的                                 |
|-----------------|-----------|--------------------------------------|
| **Stop hook**   | 仅 5-6    | 快速门禁——停止时捕获 lint/类型错误      |
| **Team Loop**   | 全部 1-7  | 每次迭代进行完整验证                    |
| **Commit gate** | 不运行层次 | 检查验证证明文件，不运行层次             |

Stop hook 只运行第 5-6 层，因为构建和测试套件可能需要几分钟。每次停止都运行全部 7 层会使 Claude 变得很难用。Team Loop 运行全部 7 层，因为它是自主运行的，正确性比速度更重要。

---

## Team Loop 状态机

Team Loop（`kova-loop.sh`）遍历 PRD 文件中的项目。每个项目经过一个状态机：

```
                        +------------------+
                        |   解析 PRD        |
                        |   提取项目        |
                        +--------+---------+
                                 |
                    对每个项目 (i = 1..N)：
                                 |
                                 v
                  +-----------------------------+
                  |       实现                    |
                  |  claude -p（独立 session）     |
                  |  "实现第 i 项"                |
                  +-------------+---------------+
                                |
                                v
                  +-----------------------------+
              +-->|         验证                  |
              |   |  verify-gate.sh（全部 7 层）   |
              |   +-------------+---------------+
              |                 |
              |          通过?--+--失败
              |                 |      |
              |                 |      v
              |                 |  +-------------------+
              |                 |  | 诊断 + 重试        |
              |                 |  | 解析失败原因        |
              |                 |  | claude -p "修复 X" |
              |                 |  +--------+----------+
              |                 |           |
              |                 |   超过最大次数?
              |                 |     否 --+-- 是 --> 熔断器
              |                 |          |
              +<---------------+-----------+
                                |
                          通过  |
                                v
                  +-----------------------------+
              +-->|         审查                  |
              |   |  run-code-review.sh          |
              |   | （独立 claude -p session）     |
              |   +-------------+---------------+
              |                 |
              |          干净?--+--有 HIGH 问题
              |            或   |      |
              |           低    |      v
              |                 |  +-------------------+
              |                 |  | 修复 HIGH 问题     |
              |                 |  | claude -p "修复"   |
              |                 |  +--------+----------+
              |                 |           |
              +<----------------+-----------+
                                |
                          干净/低
                                v
                  +-----------------------------+
                  |         提交                  |
                  |  git add + git commit        |
                  +-----------------------------+
                                |
                                v
                        下一个项目或完成
```

**上下文隔离：** 每次 `claude -p` 调用都是独立的 session。这可以防止迭代之间的上下文污染，同时控制 token 使用量。一个有 20 个项目的 PRD 会运行 20 个以上独立的 Claude session，每个都有专注的 prompt。

**熔断器：** 如果一个项目验证失败超过 `MAX_FIX_ATTEMPTS` 次（默认：5），循环会写一份失败报告然后跳到下一个项目，不会永远循环下去。

---

## 信任模型

Kova 的信任模型基于**边界强制执行**：

```
  +---------------------------------------------+
  |  Claude 的上下文                              |
  |                                              |
  |  可以：写代码、执行命令、推理                    |
  |  不可以：绕过 hook（它们在外部运行）             |
  |                                              |
  +---------------------+--+--------------------+
                        |  ^
              工具调用   |  | 放行/拦截
                        v  |
  +---------------------------------------------+
  |  Hook 边界（bash）                            |
  |                                              |
  |  通过 stdin 读取工具调用 JSON                  |
  |  决定：放行、拦截或警告                         |
  |  在 Claude 退出之后运行（stop hook）            |
  |  在工具执行之前运行（pre-tool hook）            |
  +---------------------------------------------+
```

关键特性：

1. **Claude 无法跳过验证。** Stop hook 在 Claude 完成之后才运行。在 Team Loop 中，`verify-gate.sh` 是在 `claude -p` 进程退出之后由 bash 执行的。Claude 无法编写一个 prompt 来绕过它。

2. **jq 失败 = 默认拦截。** Hook 使用 `jq` 解析工具调用 JSON。如果 `jq` 未安装或解析失败，hook 会拦截操作而不是静默放行。这可以防止通过畸形输入来绕过。

3. **用户可以禁用 hook。** 这是设计特性，不是 bug。Kova 强制执行工程纪律，不是安全策略。用户是受信任的；Claude 是被监控的。

4. **提交需要验证证明。** Commit gate（`kova-commit-gate.sh`）检查由 `verify-gate.sh` 写入的证明文件。没有这个文件，`git commit` 就会被拦截。证明文件带有时间戳和项目范围，防止重放攻击。

5. **绕过检测。** Hook 会检查已知的绕过模式（例如通过 `sh` 管道、base64 编码命令、使用 `env` 绕过 PATH 限制）。检测到的绕过尝试会被拦截并附上解释。

---

## 关键设计决定

### 为什么用 bash 而不是 prompt 编排

之前的版本使用 prompt 指令让 Claude 运行验证。Claude 跳过了——有时因为上下文太长，有时因为推理走捷径。Bash 编排是**不可跳过的**，因为验证是在 Claude 退出之后在独立进程中运行的。

### 为什么用 `mktemp` 创建临时目录

Kova 创建临时目录来存储验证输出、证明文件和锁定文件。使用 `mktemp -d`（配合 mode 700）可以防止**符号链接攻击**——即攻击者预先在可预测的临时路径创建一个指向敏感位置的符号链接。`mktemp` 生成不可预测的名称，同时原子性地创建目录。

### 为什么用 `mkdir` 做锁

Team Loop 使用 `mkdir` 作为并发锁（`mkdir "$LOCK_DIR" 2>/dev/null`）。这比基于文件的锁更好，因为 `mkdir` 在 **POSIX 上是原子性的**——它要么创建目录并成功，要么目录已存在并失败。检查和创建之间没有竞争条件。

### 为什么每次迭代用独立 `claude -p` session

每个 PRD 项目都有自己的 `claude -p` session，原因有三：

1. **上下文隔离** — 第 3 项的失败不会污染处理第 4 项时的上下文
2. **Token 预算** — 长时间的 session 会累积上下文并触及限制；新 session 从零开始
3. **故障隔离** — 如果一个 session 崩溃或挂起，只影响一个项目

### 为什么 stop hook 只运行第 5-6 层

构建和测试套件可能需要几分钟。每次 `Stop` 事件都运行全部 7 层会使交互式 Claude Code 会话变得很慢。第 5-6 层（lint + 类型检查）很快（几秒钟）并且可以捕获最常见的问题。完整验证在 Team Loop 中运行，那里延迟是可以接受的。

### 为什么安全审计仅为警告

安全建议（`npm audit`、`pip-audit` 等）经常报告传递依赖中的漏洞，而这些漏洞没有可用的修复。如果因此导致门禁失败，会阻塞所有开发直到上游发布补丁。警告可以展示这些信息但不会阻塞进度。
