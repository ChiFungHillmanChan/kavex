# Kova 配置指南

常用的 Kova 配置任务，附带需要修改的确切文件和位置。

---

## 我想修改最大迭代次数

Team Loop 默认为 **20 次迭代**。修改方法如下：

**方法 A：CLI 标志（单次运行）**

```bash
bash hooks/kova-loop.sh my-prd.md --max-iterations 10
```

**方法 B：修改 `hooks/kova-loop.sh` 中的默认值**

找到文件顶部附近的这一行：

```bash
MAX_ITERATIONS=20
```

将 `20` 改为你需要的数值。

> 你还可以使用 `--max-fix-attempts N` 控制单个卡住项目的重试次数（默认：5）。

---

## 我想跳过 stop gate

Stop gate 会在 Claude 每次停止时运行 lint + typecheck。要绕过它：

**方法 A：环境变量（临时）**

```bash
KOVA_LOOP_ACTIVE=1 claude
```

设置 `KOVA_LOOP_ACTIVE=1` 后，stop gate 会识别当前在 loop 迭代中，跳过交互检查。

**方法 B：禁用所有 hooks**

```bash
kova deactivate
```

这会关闭所有 Kova hooks（stop gate、文件保护、命令拦截、自动格式化）。使用 `kova activate` 重新启用。

---

## 我想保护额外的文件

编辑 `hooks/protect-files.sh`。其中有两个数组：

**精确文件名匹配**（针对 `.env` 类文件）：

```bash
PROTECTED_BASENAME=(
  ".env"
  ".env.local"
  # 在这里添加你的文件：
  ".env.custom"
)
```

**路径子串匹配**（针对目录或扩展名）：

```bash
PROTECTED_SUBSTRING=(
  "secrets/"
  ".pem"
  # 在这里添加你的模式：
  "internal-keys/"
)
```

精确文件名匹配可以避免误判（例如 `some.environment.ts` 不会匹配 `.env`）。子串匹配会在完整路径的任意位置查找匹配。

---

## 我想拦截额外的命令

编辑 `hooks/block-dangerous.sh`。找到 `BLOCKED_PATTERNS` 数组：

```bash
BLOCKED_PATTERNS=(
  "rm -rf /"
  "DROP TABLE"
  # 在这里添加你的模式：
  "kubectl delete namespace"
)
```

模式使用不区分大小写的子串搜索进行匹配。Kova 在匹配前会自动规范化引号和反斜杠转义字符，因此混淆变体也会被拦截。

要添加**警告**而非硬拦截，将模式添加到同一文件下方的 `WARN_PATTERNS` 数组：

```bash
WARN_PATTERNS=(
  "rm -rf"
  "force-with-lease"
  "your-pattern-here"
)
```

---

## 我想添加 Codex 跨模型审查

Kova 会自动检测 Codex 是否可用。你只需要安装它并设置 API 密钥。

**步骤 1：全局安装 Codex CLI**

```bash
npm install -g @openai/codex
```

**步骤 2：设置 API 密钥**

```bash
export OPENAI_API_KEY="sk-..."
```

将此行添加到你的 shell 配置文件（`.zshrc`、`.bashrc`）使其持久生效。

完成。Kova 的 `hooks/lib/codex-assist.sh` 会在运行时通过 `command -v codex` 检查可用性。当 Codex 可用时，会在反复失败后用于跨模型诊断和代码审查。

你还可以设置 `CODEX_TIMEOUT`（默认：120 秒）控制 Kova 等待 Codex 响应的时间。

---

## 我想修改速率限制

设置 `MAX_INVOCATIONS_PER_HOUR` 环境变量：

```bash
export MAX_INVOCATIONS_PER_HOUR=50
```

默认为每滚动小时 **100** 次调用。达到上限时，Kova 会暂停并显示倒计时，等最旧的调用过期后自动继续。

---

## 我想添加自定义格式化工具

编辑 `hooks/format.sh`。此 hook 在每次 Write/Edit 操作后运行。在 `case "$EXT" in` 代码块中添加新的 case：

```bash
  swift)
    if command -v swiftformat &>/dev/null; then
      swiftformat "$FILE" 2>/dev/null || true
    fi
    ;;
```

模式始终相同：
1. 匹配文件扩展名
2. 检查格式化工具命令是否存在
3. 使用 `2>/dev/null || true` 运行，确保失败不会阻塞 Claude

现有格式化工具：Prettier（JS/TS/CSS/HTML/MD/YAML）、Ruff/Black（Python）、gofmt（Go）、rustfmt（Rust）、RuboCop（Ruby）、google-java-format（Java）、dotnet format（C#）、taplo（TOML）、jq（JSON）。

---

## 我想使用 dry-run 模式

使用 `--dry-run` 预览 Team Loop 将要执行的操作，不会实际执行任何内容：

```bash
bash hooks/kova-loop.sh my-prd.md --dry-run
```

这会解析 PRD、检测你的技术栈、打印项目列表和配置，然后退出，不做任何更改。适合在正式运行前验证 PRD 是否被正确解析。
