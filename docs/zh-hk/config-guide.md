# Kavex 設定指南

常用嘅 Kavex 設定任務，附帶要改嘅確切檔案同位置。

---

## 我想改最大迭代次數

Team Loop 預設係 **20 次迭代**。改法如下：

**方法 A：CLI 旗標（每次執行）**

```bash
bash hooks/kavex-loop.sh my-prd.md --max-iterations 10
```

**方法 B：改 `hooks/kavex-loop.sh` 入面嘅預設值**

搵到呢一行（近檔案頂部）：

```bash
MAX_ITERATIONS=20
```

將 `20` 改成你想要嘅數字。

> 你亦可以用 `--max-fix-attempts N` 控制單一卡住項目嘅重試次數（預設：5）。

---

## 我想跳過 stop gate

Stop gate 會喺 Claude 每次停止嘅時候執行 lint + typecheck。要略過佢：

**方法 A：環境變數（臨時）**

```bash
KAVEX_LOOP_ACTIVE=1 claude
```

設定咗 `KAVEX_LOOP_ACTIVE=1`，stop gate 就知道自己喺 loop 迭代入面，會跳過互動檢查。

**方法 B：停用所有 hooks**

```bash
kavex deactivate
```

呢個會關閉所有 Kavex hooks（stop gate、檔案保護、指令封鎖、自動格式化）。用 `kavex activate` 重新啟用。

---

## 我想保護額外嘅檔案

改 `hooks/protect-files.sh`。入面有兩個陣列：

**精確檔名配對**（針對 `.env` 之類嘅檔案）：

```bash
PROTECTED_BASENAME=(
  ".env"
  ".env.local"
  # 喺呢度加你嘅檔案：
  ".env.custom"
)
```

**路徑子字串配對**（針對目錄或副檔名）：

```bash
PROTECTED_SUBSTRING=(
  "secrets/"
  ".pem"
  # 喺呢度加你嘅模式：
  "internal-keys/"
)
```

精確檔名配對可以避免誤判（例如 `some.environment.ts` 唔會配對到 `.env`）。子字串配對會喺完整路徑任何位置搵匹配。

---

## 我想封鎖額外嘅指令

改 `hooks/block-dangerous.sh`。搵到 `BLOCKED_PATTERNS` 陣列：

```bash
BLOCKED_PATTERNS=(
  "rm -rf /"
  "DROP TABLE"
  # 喺呢度加你嘅模式：
  "kubectl delete namespace"
)
```

模式會用大小寫不敏感嘅子字串搜尋嚟配對。Kavex 配對之前會自動正規化引號同反斜線跳脫字元，所以混淆過嘅變體都會被截獲。

要加**警告**而唔係硬封鎖，就加去同一個檔案下面嘅 `WARN_PATTERNS` 陣列：

```bash
WARN_PATTERNS=(
  "rm -rf"
  "force-with-lease"
  "your-pattern-here"
)
```

---

## 我想加 Codex 跨模型審查

Kavex 會自動偵測 Codex 有冇裝。你只需要裝好同設定 API key。

**步驟 1：全域安裝 Codex CLI**

```bash
npm install -g @openai/codex
```

**步驟 2：設定 API key**

```bash
export OPENAI_API_KEY="sk-..."
```

將呢行加入你嘅 shell 設定檔（`.zshrc`、`.bashrc`）令佢持久生效。

搞掂。Kavex 嘅 `hooks/lib/codex-assist.sh` 會喺執行時用 `command -v codex` 檢查。有 Codex 嘅話，會喺重複失敗後用佢做跨模型診斷同代碼審查。

你亦可以設定 `CODEX_TIMEOUT`（預設：120 秒）控制 Kavex 等 Codex 回應嘅時間。

---

## 我想改速率限制

設定 `MAX_INVOCATIONS_PER_HOUR` 環境變數：

```bash
export MAX_INVOCATIONS_PER_HOUR=50
```

預設係每滾動小時 **100** 次調用。達到上限嘅時候，Kavex 會暫停並顯示倒數計時，等最舊嘅調用過期後自動繼續。

---

## 我想加自訂格式化工具

改 `hooks/format.sh`。呢個 hook 會喺每次 Write/Edit 操作後執行。喺 `case "$EXT" in` 區塊加一個新嘅 case：

```bash
  swift)
    if command -v swiftformat &>/dev/null; then
      swiftformat "$FILE" 2>/dev/null || true
    fi
    ;;
```

模式永遠係一樣嘅：
1. 配對副檔名
2. 檢查格式化工具指令存唔存在
3. 用 `2>/dev/null || true` 執行，確保失敗唔會阻擋 Claude

現有嘅格式化工具：Prettier（JS/TS/CSS/HTML/MD/YAML）、Ruff/Black（Python）、gofmt（Go）、rustfmt（Rust）、RuboCop（Ruby）、google-java-format（Java）、dotnet format（C#）、taplo（TOML）、jq（JSON）。

---

## 我想用 dry-run 模式

用 `--dry-run` 預覽 Team Loop 會做咩，唔會執行任何嘢：

```bash
bash hooks/kavex-loop.sh my-prd.md --dry-run
```

呢個會解析 PRD、偵測你嘅技術棧、列印項目清單同設定，然後退出，唔會作任何更改。適合喺正式執行之前驗證 PRD 有冇被正確解析。
