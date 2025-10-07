# Claude Code 設定ガイド

このディレクトリには、Claude Codeの設定ファイルのサンプルを配置しています。

## TL;DR

```bash
# グローバル設定
mkdir -p ~/.claude
ln -s $(pwd)/global_CLAUDE.md ~/.claude/CLAUDE.md

# カスタムコマンド
mkdir -p ~/.claude/commands
ln -s $(pwd)/commands/commit-push.md ~/.claude/commands/commit-push.md

# 権限設定
ln -s $(pwd)/settings.json.sample ~/.claude/settings.json

# または setup.sh を使う
cd /path/to/dotfiles
./setup.sh
```

## 初期設定

### 1. プロジェクトの初期化

プロジェクトのルートディレクトリで Claude Code を起動：

```bash
cd /path/to/your/project
claude
```

Claude Code の対話モード内で以下のコマンドを実行：

```
/init
```

これで `.claude/` ディレクトリと基本的な設定ファイル（`project_instructions.md`, `ignore.txt` など）が自動生成されます。

### 2. グローバル設定

グローバル設定は `~/.config/claude-code/` に配置します：

```bash
mkdir -p ~/.config/claude-code
```

#### シンボリックリンクで設定を反映

このdotfilesリポジトリから設定をシンボリックリンクで反映する場合：

```bash
# グローバル設定（project_instructions）
ln -s $(pwd)/global_CLAUDE.md ~/.config/claude-code/project_instructions.md

# グローバル設定（ignore）
ln -s $(pwd)/global_ignore_sample.txt ~/.config/claude-code/ignore.txt

# または ~/.claude/ に配置する場合
mkdir -p ~/.claude
ln -s $(pwd)/global_CLAUDE.md ~/.claude/CLAUDE.md
```

**注意**: シンボリックリンクを作成する前に、既存のファイルがある場合はバックアップを取ってください。

### 3. MCP サーバーの設定（オプション）

#### Serena MCP Server

セマンティックなコード操作を提供するMCPサーバー。プロジェクトごとに以下のコマンドを実行：

```bash
# Homebrewでuvをインストール
brew install uv
# プロジェクトのルートディレクトリで実行
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)
```

**機能:**
- シンボル単位でのコード検索・編集
- ファイル構造の効率的な把握
- リファクタリング支援

**注意:** プロジェクトごとに設定が必要です。一度実行すれば、そのプロジェクトで継続的に使用できます。

#### おすすめの初期設定

**~/.config/claude-code/project_instructions.md**
```markdown
# グローバルな開発ガイドライン

- コミットメッセージは日本語で記述
- gitmoji を使用する
- コードコメントは日本語可
- テストコードは必須ではない（プロジェクトによる）
```

**~/.config/claude-code/ignore.txt**
```
node_modules/
.next/
dist/
build/
.env
.env.local
*.log
.DS_Store
```

## プロジェクト固有の設定例

### プロジェクトの `.claude/project_instructions.md`

```markdown
# このプロジェクトについて

## 技術スタック
- TypeScript
- React
- Next.js

## コーディング規約
- ESLintのルールに従う
- Prettier でフォーマット
- コンポーネントはfunctional componentで記述

## コミットルール
- Conventional Commits形式
- gitmoji使用
```

### プロジェクトの `.claude/ignore.txt`

```
# ビルド成果物
dist/
build/
.next/

# 依存関係
node_modules/

# 環境変数
.env
.env.local
.env.*.local

# ログ
*.log
npm-debug.log*

# OS
.DS_Store
Thumbs.db
```

## カスタムコマンド

`.claude/commands/` ディレクトリにMarkdownファイルを配置すると、スラッシュコマンドとして使用できます。

### コマンドファイルの作成

ファイル名がコマンド名になります（拡張子 `.md` を除く）。

#### 基本的な形式

```markdown
---
description: コマンドの説明
---

# コマンド名

コマンドの詳細な説明や手順をここに記述します。
```

#### 提供しているコマンド

##### `/commit-push`

現在の変更を適切にコミットしてプッシュするコマンド。

- gitmoji付きのコミットメッセージを作成
- 1コミット = 1つの論理的な変更として整理
- 関連ファイルのみを選択的にステージング

詳細は [`commands/commit-push.md`](./commands/commit-push.md) を参照。

### カスタムコマンドの反映

このdotfilesリポジトリのコマンドを使用する場合：

```bash
# commandsディレクトリごとシンボリックリンクを作成
ln -s $(pwd)/claude/commands ~/.claude/commands

# または個別にリンク
mkdir -p ~/.claude/commands
ln -s $(pwd)/claude/commands/commit-push.md ~/.claude/commands/commit-push.md
```

**注意**: 新しいコマンドを追加した場合、Claude Codeセッションの再起動が必要です。

## ベストプラクティス

### CLAUDE.md について

Anthropic公式では `CLAUDE.md` という名前も推奨されています。以下の場所に配置できます：

- プロジェクトルート: `.claude/CLAUDE.md`
- ホームフォルダ: `~/.claude/CLAUDE.md`
- グローバル設定: `~/.config/claude-code/project_instructions.md`

### 推奨事項

1. **グローバル設定を優先**
   - 共通のルールは `~/.config/claude-code/` に配置
   - プロジェクト固有の設定は最小限にする
   - dotfilesリポジトリで管理すると便利

2. **設定は簡潔に**
   - 人間が読みやすい形式で記述
   - 必要に応じて会話中に `# CLAUDE.md` で追加・改善

3. **Bashコマンドを明記**
   - ビルドコマンド、テストコマンドなど
   - よく使うコマンドを記載しておくと効率的

4. **権限設定の管理**
   - `/permissions` コマンドで確認・設定
   - `.claude/settings.json` で管理
   - 段階的に許可範囲を広げる
   - 📖 [詳しい説明はこちら](./settings_guide.md)
   - 💾 [サンプルファイル](./settings.json.sample)

## このディレクトリの内容

### 設定ファイルサンプル
- `global_CLAUDE.md` - グローバル設定のテンプレート
- `project_CLAUDE*.md` - 言語・用途別プロジェクト設定サンプル
- `ignore_sample.txt` / `global_ignore_sample.txt` - 無視ファイル設定
- `settings.json.sample` - 権限設定サンプル

### カスタムコマンド
- `commands/commit-push.md` - コミット&プッシュ実行コマンド

### ガイド・テンプレート
- `settings_guide.md` - settings.json の詳しい説明
- `prompt_templates.md` - よく使うプロンプト集

## 参考リンク

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Best Practices (Anthropic公式)](https://www.anthropic.com/engineering/claude-code-best-practices)
- [WantedlyのClaude Code活用事例](https://www.wantedly.com/companies/wantedly/post_articles/981006)
