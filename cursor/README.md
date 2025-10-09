# Cursor templates in dotfiles

このディレクトリは、各リポジトリで再利用できる Cursor 設定テンプレートを格納します。

## 含まれるテンプレート
- `rules/repo-guidelines.mdc`: Project Rules の雛形（必要に応じて RuleType を `Always`/`Auto Attached`/`Agent Requested`/`Manual` に変更）。
- `agents.md`: Agents の雛形。
- `mcp.json`: MCP 設定の雛形（`cursor/mcp.json`）。

## 使い方
1. 対象リポジトリのルートに `.cursor/` ディレクトリを作成。
2. 本テンプレートをコピーし、プロジェクトに合わせて調整。
3. RuleType と Description を用途に合わせて更新。

## 参考
- Project Rules: `https://docs.cursor.com/ja/context/rules`
- 解説: `https://zenn.dev/globis/articles/cursor-project-rules`
