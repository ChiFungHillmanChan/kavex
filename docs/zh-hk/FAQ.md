# 常見問題

## 點解用 bash 編排而唔係靠 prompt 自我編排？

Prompt 式嘅執行依賴 Claude 自己遵守指示，但 prompt 合規係可以被跳過嘅 — Claude 有機會自己決定略過驗證或者審查步驟。用 bash 編排嘅話，`kova-loop.sh` 會喺 Claude 退出 session 之後先至行驗證。因為 Claude 已經退出咗，佢冇辦法跳過驗證步驟。Bash 係老闆，Claude 係員工。

## 支援咩語言同技術棧？

Kova 支援 **Node.js、Python、Go、Rust、Ruby、Java 同 .NET**。技術棧由 `detect-stack.sh` 自動偵測，佢會搵你專案入面嘅特徵檔案（例如 Node.js 嘅 `package.json`、Rust 嘅 `Cargo.toml`、Go 嘅 `go.mod`）。驗證閘同自動格式化工具會根據偵測到嘅技術棧自動使用正確嘅工具。

## `kova` 同 `kova-full` 兩個插件有咩分別？

| 插件 | 包含內容 |
|------|---------|
| **kova** | Slash 指令（`/plan`、`/verify-app`、`/code-review` 等）+ 工程協議技能 |
| **kova-full** | `kova` 嘅所有嘢，加上安全鈎、驗證閘、自動格式化、commit 閘同 Team Loop |

如果你淨係想要工作流程指令而唔需要強制執行，揀 `kova`。如果你想要完整嘅自主工程系統連 bash 編排鈎，揀 `kova-full`。

## Kova 同 Ralph 比較有咩分別？

[Ralph](https://github.com/frankbria/ralph-claude-code) 啟發咗 bash 編排器嘅模式 — 即係由 bash 控制迴圈而唔係靠 prompt。Kova 喺呢個基礎上加入咗：7 層驗證閘、卡住迴圈嘅斷路器、多模型審查（Claude + 可選嘅 Codex）、儲存喺 `.kova-loop/` 嘅可恢復狀態、速率限制，同埋 tmux 監控面板。

## Kova 可唔可以同 OpenAI Codex 一齊用？

Codex 整合係**可選嘅**。如果你裝咗 `@openai/codex`，Kova 可以用 `codex-assist.sh` 做跨模型代碼審查 — 畀另一個模型出第二個意見。呢個唔係核心功能嘅必要條件。Kova 淨用 Claude Code 已經可以完整運作。

## 如果冇裝 `jq` 會點？

鈎會**為咗安全封鎖操作**（fail-closed 設計）。與其喺冇正確 JSON 解析嘅情況下靜靜雞容許可能危險嘅操作，Kova 會拒絕繼續。裝返 `jq` 就可以解決：`brew install jq`（macOS）、`apt install jq`（Debian/Ubuntu）或者 `dnf install jq`（Fedora）。

## 鈎可唔可以被繞過？

可以，而且呢個係設計上嘅決定。用戶永遠掌控一切。你可以用 `kova deactivate` 停用鈎，或者編輯 `settings.json` 移除鈎嘅條目。Kova 喺活躍 session 期間執行紀律 — 佢唔會鎖住你自己嘅工具。要重新啟用，行 `kova activate`。

## 點樣加入新語言嘅支援？

1. 編輯 `detect-stack.sh`，加入你語言嘅偵測邏輯（例如檢查 Elixir 嘅 `mix.exs` 特徵檔案）。
2. 編輯 `verify-gate.sh`，加入該語言對應嘅 build、test、lint 同 typecheck 指令。
3. 可選：如果你嘅語言有標準格式化工具，更新自動格式化鈎。

## Kova 用喺生產環境安唔安全？

Kova 係一個**純開發階段工具**。鈎只會喺 Claude Code session 入面運行 — 唔會喺 CI/CD 流程、生產部署或者 Claude Code 以外嘅任何地方執行。Kova 儀器化你嘅開發工作流程，唔會掂到你嘅生產系統。

## 點樣停用個別鈎而唔係全部停用？

編輯 `hooks.json` 或者你專案嘅 `settings.json`，移除或者註解掉特定嘅鈎條目。例如，你可以保持 commit 閘啟用同時停用 stop 鈎，或者反過來。之後行 `kova status` 確認邊啲鈎仲係啟用嘅。

## Stop 鈎同 Team Loop 有咩分別？

**Stop 鈎**（`verify-on-stop.sh`）係一個快速閘，每次 Claude 停止嘅時候行 **lint + typecheck**。佢可以快速捉到基本錯誤。**Team Loop**（`kova-loop.sh`）係完整嘅自主工作流程，為每個 PRD 項目行 **7 層驗證**（build、test、lint、typecheck、security 等），加上代碼審查同自動 commit。Stop 鈎係安全網；Team Loop 係完整嘅工程流程。

## Team Loop 中斷之後可唔可以恢復？

可以。Team Loop 會將狀態儲存喺 `.kova-loop/` 目錄入面，包括邊啲 PRD 項目已經完成、驗證結果同審查狀態。如果迴圈被中斷（例如當機、網絡問題或者手動停止），只需要重新行同一個 `/kova:loop` 指令。佢會由上次停低嘅地方繼續。
