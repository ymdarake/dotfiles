# Cursor templates in dotfiles

このディレクトリは、各リポジトリで再利用できる Cursor 設定テンプレートを格納します。

## 含まれるテンプレート
- `rules/`: 開発ガイドライン
  - `global-guidelines.mdc`: 全プロジェクト共通の開発方針
  - `react-guidelines.mdc`: React固有のベストプラクティス
  - `go-guidelines.mdc`: Go固有のベストプラクティス
  - `terraform-guidelines.mdc`: Terraform固有のベストプラクティス
  - `typescript-guidelines.mdc`: TypeScript固有のベストプラクティス
- `mcp.json`: MCP 設定の雛形

## 各プロジェクトでのセットアップ手順

### 1. 自動セットアップ（推奨）

```bash
# プロジェクトディレクトリで実行
/path/to/dotfiles/cursor/setup-cursor.sh

# または、特定のプロジェクトディレクトリを指定
/path/to/dotfiles/cursor/setup-cursor.sh /path/to/project
```

このスクリプトは以下を自動でセットアップします：
- `.cursor/` ディレクトリ全体のコピー
- `.gitignore` への Cursor設定追加

### 2. 手動セットアップ

```bash
# プロジェクトルートで実行
cp -r /path/to/dotfiles/cursor .cursor
```

### 3. プロジェクト固有の設定

プロジェクト固有のルールは `.cursor/rules/` ディレクトリに追加してください。

#### 言語・フレームワーク別ガイドライン

`rules/` ディレクトリには以下のガイドラインが含まれています：

- **global-guidelines.mdc**: 全プロジェクト共通の開発方針
- **react-guidelines.mdc**: React固有のベストプラクティス
- **go-guidelines.mdc**: Go固有のベストプラクティス
- **terraform-guidelines.mdc**: Terraform固有のベストプラクティス
- **typescript-guidelines.mdc**: TypeScript固有のベストプラクティス

プロジェクトに応じて適切なガイドラインを参照してください。

### 4. 設定ファイルの優先順位

Cursor は以下の順序で設定ファイルを読み込みます：

1. `./.cursor/rules/*.mdc`（プロジェクト固有）
2. Cursor のデフォルト設定

### 5. プロジェクトごとの初期化

新しいプロジェクトを開始する際：

```bash
# プロジェクトディレクトリで実行
cp -r /path/to/dotfiles/cursor .cursor

# プロジェクト固有の設定を追加
touch .cursor/rules/project-specific.mdc
```

## 使い方
1. 対象リポジトリのルートに `.cursor/` ディレクトリを作成
2. 本テンプレートをコピーし、プロジェクトに合わせて調整
3. `.cursor/rules/` にプロジェクト固有のルールを追加
4. 言語・フレームワークに応じて適切なガイドラインを参照

## 参考
- Project Rules: `https://docs.cursor.com/ja/context/rules`
- 解説: `https://zenn.dev/globis/articles/cursor-project-rules`
