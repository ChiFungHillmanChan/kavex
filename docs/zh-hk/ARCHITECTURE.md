# Kova 架構文件

## 概覽

Kova 係一個 **bash 強制執行嘅工程協議**，專為 Claude Code 設計。核心原則：

> **Claude 係做嘢嗰個。Bash 係話事人。**

Claude Code 支援 hook 系統，可以喺工具呼叫（寫檔案、執行 bash 指令、停止事件）執行之前同之後攔截。Kova 透過 `hooks.json` 註冊 hook，喺呢啲攔截點執行 shell 腳本。因為 hook 係喺 Claude 嘅上下文之外——喺獨立嘅 bash 進程入面執行——所以 Claude 冇辦法跳過、修改或者迴避驗證。

呢個唔係 prompt 工程。呢個係**流程強制執行**。

---

## Hook 執行流程

Claude Code 嘅 hook 系統會將工具呼叫嘅元數據以 JSON 格式透過 stdin 傳俾 hook 腳本。每個 hook 腳本讀取 JSON、檢查內容，然後返回決定。

```
  Claude 呼叫工具 (Bash, Write, Edit, Stop)
         |
         v
  +------------------+
  |   hooks.json     |  Matcher 揀邊啲 hook 要觸發
  |   (matcher)      |  例如 "Bash", "Write|Edit|MultiEdit", "Stop"
  +--------+---------+
           |
           v
  +------------------+
  | PreToolUse hook  |  喺工具執行之前運行
  |  (stdin: JSON)   |
  +--------+---------+
           |
     +-----+------+
     |            |
   放行         攔截
     |         (exit 2，印出原因)
     v
  +------------------+
  |  工具執行         |
  +--------+---------+
           |
           v
  +------------------+
  | PostToolUse hook  |  喺工具執行之後運行
  |  (例如 format.sh) |
  +------------------+
```

### 已註冊嘅 Hook

```
PreToolUse:
  Bash           -> block-dangerous.sh    攔截 rm -rf /、DROP TABLE、force push 等等
                 -> kova-commit-gate.sh   冇驗證證明就攔截 git commit
  Write|Edit     -> protect-files.sh      攔截寫入 .env、credentials 等敏感檔案

PostToolUse:
  Write|Edit     -> format.sh            自動格式化寫入嘅檔案（Prettier、Ruff、gofmt 等）

Stop:
  (全部)          -> verify-on-stop.sh     快速閘口：Claude 停止前跑 lint + 類型檢查
```

---

## 7 層驗證

驗證閘口（`verify-gate.sh`）最多跑 7 層檢查。每一層會自動偵測專案技術棧（Node.js、Python、Go、Rust、Ruby、Java、.NET）然後跑對應嘅工具。

```
  層次   檢查               跑咩                              失敗點
  ----   ----------------   --------------------------------  --------
  [1]    構建 / 編譯        npm run build、go build、          FAIL
                            cargo build、mvn compile 等
  [2]    單元測試            jest、vitest、pytest、go test、    FAIL
                            cargo test（有 flaky 重試）
  [3]    整合測試            npm run test:integration           FAIL
                            （有 flaky 重試）
  [4]    端到端測試          Playwright                         FAIL
                            （有 flaky 重試）
  [5]    Lint               eslint、ruff、clippy、              FAIL
                            golangci-lint、rubocop
  [6]    類型檢查            tsc --noEmit、mypy、pyright、      FAIL
                            go vet、cargo check
  [7]    安全審計            npm audit、pip-audit、              只警告
                            cargo audit、govulncheck
```

**Flaky 重試：** 第 2-4 層（測試層）失敗時會自動重試一次先至報失敗。咁可以處理間歇性嘅測試唔穩定問題，但唔會掩蓋真正嘅錯誤。

**安全審計（第 7 層）：** 報告漏洞但唔會令閘口失敗。呢個係刻意設計——安全建議通常冇即時修復方案，唔應該阻住開發。

### 邊度跑咩

| 場景             | 跑嘅層次    | 目的                                 |
|-----------------|-----------|--------------------------------------|
| **Stop hook**   | 只跑 5-6  | 快速閘口——喺停止時捉 lint/類型錯誤      |
| **Team Loop**   | 全部 1-7  | 每次迭代做完整驗證                      |
| **Commit gate** | 唔跑層次   | 檢查驗證證明檔案，唔係跑層次              |

Stop hook 只跑第 5-6 層，因為構建同測試套件可能要幾分鐘。每次停止都跑晒 7 層會令 Claude 好難用。Team Loop 跑晒全部 7 層，因為佢係自主運行，正確性比速度重要。

---

## Team Loop 狀態機

Team Loop（`kova-loop.sh`）遍歷 PRD 檔案入面嘅項目。每個項目經過一個狀態機：

```
                        +------------------+
                        |   解析 PRD        |
                        |   提取項目        |
                        +--------+---------+
                                 |
                    對每個項目 (i = 1..N)：
                                 |
                                 v
                  +-----------------------------+
                  |       實現                    |
                  |  claude -p（獨立 session）     |
                  |  「實現第 i 項」               |
                  +-------------+---------------+
                                |
                                v
                  +-----------------------------+
              +-->|         驗證                  |
              |   |  verify-gate.sh（全部 7 層）   |
              |   +-------------+---------------+
              |                 |
              |          通過?--+--失敗
              |                 |      |
              |                 |      v
              |                 |  +-------------------+
              |                 |  | 診斷 + 重試        |
              |                 |  | 解析失敗原因        |
              |                 |  | claude -p 「修好 X」|
              |                 |  +--------+----------+
              |                 |           |
              |                 |   超過最大次數?
              |                 |     未 --+-- 係 --> 熔斷器
              |                 |          |
              +<---------------+-----------+
                                |
                          通過  |
                                v
                  +-----------------------------+
              +-->|         審查                  |
              |   |  run-code-review.sh          |
              |   | （獨立 claude -p session）     |
              |   +-------------+---------------+
              |                 |
              |          乾淨?--+--有 HIGH 問題
              |            或   |      |
              |           低    |      v
              |                 |  +-------------------+
              |                 |  | 修復 HIGH 問題     |
              |                 |  | claude -p 「修好」  |
              |                 |  +--------+----------+
              |                 |           |
              +<----------------+-----------+
                                |
                          乾淨/低
                                v
                  +-----------------------------+
                  |         提交                  |
                  |  git add + git commit        |
                  +-----------------------------+
                                |
                                v
                        下一個項目或者完成
```

**上下文隔離：** 每次 `claude -p` 呼叫都係獨立嘅 session。咁可以防止迭代之間嘅上下文污染，同時控制 token 用量。一個有 20 個項目嘅 PRD 會跑 20 個以上獨立嘅 Claude session，每個都有專注嘅 prompt。

**熔斷器：** 如果一個項目驗證失敗超過 `MAX_FIX_ATTEMPTS` 次（預設：5），loop 會寫一份失敗報告然後跳去下一個項目，唔會永遠 loop 落去。

---

## 信任模型

Kova 嘅信任模型基於**邊界強制執行**：

```
  +---------------------------------------------+
  |  Claude 嘅上下文                              |
  |                                              |
  |  可以：寫 code、跑指令、推理                    |
  |  唔可以：繞過 hook（佢哋喺外面跑）              |
  |                                              |
  +---------------------+--+--------------------+
                        |  ^
              工具呼叫   |  | 放行/攔截
                        v  |
  +---------------------------------------------+
  |  Hook 邊界（bash）                            |
  |                                              |
  |  透過 stdin 讀取工具呼叫 JSON                  |
  |  決定：放行、攔截或者警告                       |
  |  喺 Claude 退出之後運行（stop hook）            |
  |  喺工具執行之前運行（pre-tool hook）            |
  +---------------------------------------------+
```

關鍵特性：

1. **Claude 冇辦法跳過驗證。** Stop hook 喺 Claude 完成之後先至跑。喺 Team Loop 入面，`verify-gate.sh` 係喺 `claude -p` 進程退出之後由 bash 執行。Claude 冇辦法寫一個 prompt 去迴避佢。

2. **jq 失敗 = 預設攔截。** Hook 用 `jq` 解析工具呼叫 JSON。如果 `jq` 未裝或者解析失敗，hook 會攔截操作而唔係靜靜咁放行。咁可以防止透過畸形輸入嚟繞過。

3. **用戶可以停用 hook。** 呢個係設計嚟嘅，唔係 bug。Kova 強制工程紀律，唔係安全政策。用戶係受信任嘅；Claude 係被監控嘅。

4. **提交需要驗證證明。** Commit gate（`kova-commit-gate.sh`）檢查由 `verify-gate.sh` 寫入嘅證明檔案。冇呢個檔案，`git commit` 就會被攔截。證明檔案有時間戳同專案範圍，防止重播攻擊。

5. **繞過偵測。** Hook 會檢查已知嘅繞過模式（例如透過 `sh` 管道、base64 編碼指令、用 `env` 繞過 PATH 限制）。偵測到嘅繞過嘗試會被攔截並附上解釋。

---

## 關鍵設計決定

### 點解用 bash 唔用 prompt 編排

之前嘅版本用 prompt 指示叫 Claude 跑驗證。Claude 跳過咗——有時因為上下文太長，有時因為推理抄捷徑。Bash 編排係**冇得跳過嘅**，因為驗證係喺 Claude 退出之後喺獨立進程入面跑。

### 點解用 `mktemp` 建臨時目錄

Kova 建臨時目錄嚟存驗證輸出、證明檔案同鎖定檔案。用 `mktemp -d`（配合 mode 700）可以防止**符號連結攻擊**——即係攻擊者預先喺可預測嘅臨時路徑建一個指向敏感位置嘅符號連結。`mktemp` 產生唔可預測嘅名，同時原子性噉建目錄。

### 點解用 `mkdir` 做鎖

Team Loop 用 `mkdir` 做並發鎖（`mkdir "$LOCK_DIR" 2>/dev/null`）。呢個比基於檔案嘅鎖好，因為 `mkdir` 喺 **POSIX 上係原子性嘅**——佢要麼建到目錄同時成功，要麼目錄已經存在同時失敗。喺檢查同建立之間冇競爭條件。

### 點解每次迭代用獨立 `claude -p` session

每個 PRD 項目都有自己嘅 `claude -p` session，原因有三：

1. **上下文隔離** — 第 3 項嘅失敗唔會污染處理第 4 項時嘅上下文
2. **Token 預算** — 長時間嘅 session 會累積上下文同撞到限制；新 session 由零開始
3. **故障隔離** — 如果一個 session crash 或者 hang 咗，只影響一個項目

### 點解 stop hook 只跑第 5-6 層

構建同測試套件可能要幾分鐘。每次 `Stop` 事件都跑晒 7 層會令互動式 Claude Code session 慢到唔想用。第 5-6 層（lint + 類型檢查）好快（幾秒鐘）同時可以捉到最常見嘅問題。完整驗證喺 Team Loop 入面跑，嗰度延遲係可以接受嘅。

### 點解安全審計只係警告

安全建議（`npm audit`、`pip-audit` 等）經常報告傳遞依賴入面嘅漏洞，而呢啲漏洞冇可用嘅修復。如果因為呢啲而令閘口失敗，會阻住所有開發直到上游發布補丁。警告可以展示呢啲資訊但唔會阻住進度。
