# Codex 会话过滤

`codex-view.ps1` 会读取目录中最新的
`codex-session-*.md`，按顶层角色标题过滤内容，并生成新的 Markdown
文件。原始导出不会被修改。

## 常用命令

在当前目录的 PowerShell 中执行：

```powershell
# 只保留 User 和 Assistant，隐藏所有 Activity
.\codex-view.ps1 assistant

# 只保留 Activity
.\codex-view.ps1 activity

# 只保留 User
.\codex-view.ps1 user

# 完整内容
.\codex-view.ps1 all
```

生成后可直接在编辑器的 Markdown 预览中切换对应文件。如果环境中安装了
VS Code 的 `code` 命令，可用 `-Open` 自动打开：

```powershell
.\codex-view.ps1 assistant -Open
.\codex-view.ps1 activity -Open
```

## 指定文件或输出

省略第二个参数时，脚本自动选择目录中最近修改的会话导出。也可显式指定：

```powershell
.\codex-view.ps1 assistant .\codex-session-xxxx.md
.\codex-view.ps1 activity .\codex-session-xxxx.md -Output .\only-activity.md
```

如果目录中有多个导出，建议使用 PowerShell 的上下方向键重复切换上一条命令：

```powershell
.\codex-view.ps1 assistant -Open
.\codex-view.ps1 activity -Open
```

这些命令会在同一个 VS Code 窗口中打开不同的预览标签，之后只需点击标签即可
切换。也可以按 `Ctrl+R`（PowerShell）搜索并重新执行历史命令。

## 识别规则

脚本只识别位于代码围栏之外的顶层标题：

```text
## User
## Assistant
## Activity
```

`assistant` 模式会保留 User，以便 AI 回复仍有提问上下文。每个顶层区块在遇到
下一个角色标题时结束，因此区块中的普通二级、三级 Markdown 标题仍会保留。
