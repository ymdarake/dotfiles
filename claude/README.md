# Claude Code 設定ガイド

このディレクトリには、Claude Codeの設定ファイルのサンプルを配置しています。

## TL;DR

```bash
cd /path/to/dotfiles/claude

# --- 基本設定 ---
mkdir -p ~/.claude
ln -sf $(pwd)/global_CLAUDE.md ~/.claude/CLAUDE.md
ln -sf $(pwd)/settings.json.sample ~/.claude/settings.json

# --- カスタムコマンド（スラッシュコマンド） ---
mkdir -p ~/.claude/commands
ln -sf $(pwd)/commands/commit-push.md ~/.claude/commands/
ln -sf $(pwd)/commands/review.md ~/.claude/commands/

# --- テストランナースクリプト ---
mkdir -p ~/.claude/scripts
ln -sf $(pwd)/scripts/flutter-test-runner.sh ~/.claude/scripts/
ln -sf $(pwd)/scripts/maestro-test-runner.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh

# --- hooks（Stop hook 等） ---
mkdir -p ~/.claude/hooks
ln -sf $(pwd)/hooks/check-diff-size.sh ~/.claude/hooks/
ln -sf $(pwd)/hooks/wave-guardrail.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# --- スキル ---
# ディレクトリごとシンボリックリンク（新規スキルも自動反映）
rm -rf ~/.claude/skills 2>/dev/null
ln -sf $(pwd)/skills ~/.claude/skills

# --- 共有メモリ ---
# エージェント間で共有するパターン記録。ディレクトリごとリンク
rm -rf ~/.claude/shared-memory 2>/dev/null
ln -sf $(pwd)/shared-memory ~/.claude/shared-memory

# --- エージェント定義（Flutter プロジェクト用） ---
# グローバルに配置する場合:
rm -rf ~/.claude/agents 2>/dev/null
ln -sf $(pwd)/agents ~/.claude/agents
# プロジェクト固有にする場合は、各プロジェクトの .claude/agents/ にリンク
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

### プロジェクトごとの参照先（重要）

- @claude は「プロジェクトルートの `CLAUDE.md`」を最優先で参照してください。
- 推奨の参照順序（上から優先）:
  1) `./CLAUDE.md`（リポジトリ直下）
  2) `~/.claude/CLAUDE.md`（ユーザーグローバル）
  3) `~/.config/claude-code/project_instructions.md`（Claude Code グローバル）

プロジェクト固有の指示は、まずリポジトリ直下の `CLAUDE.md` に記載し、必要に応じて `.claude/` 配下に詳細を分割してください。

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
# 個別にリンク
mkdir -p ~/.claude/commands
ln -sf $(pwd)/claude/commands/commit-push.md ~/.claude/commands/
ln -sf $(pwd)/claude/commands/review.md ~/.claude/commands/
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
- `settings.json.sample` - 権限設定サンプル（hooks の参照パスも含む）

### エージェント定義 (`agents/`)
- `flutter-developer.md` - TDD サイクルを自律実行する Flutter エンジニア
- `flutter-layer-first-architect.md` - Layer-first DDD 設計支援
- `flutter-unit-test.md` - ユニットテスト自動生成
- `architecture-advisor.md` - アーキテクチャ選定支援
- `maestro-e2e.md` - Maestro E2E テスト作成・実行

### スキル (`skills/`)
- `flutter-tdd-cycle/` - TDD Red-Green-Refactor オーケストレーション
- `flutter-po/` - プロダクトオーナースキル
- `flutter-plan/` - 実装前の DDD 影響分析・計画策定
- `flutter-wave-orchestrator/` - 複数ストーリー Wave 並列実装
- `gemini-code-review/` - Gemini によるコードレビュー
- `flutter-ddd-review/` - DDD アーキテクチャレビュー
- `flutter-dialog/` - ダイアログ定型パターン生成
- `flutter-fl-chart-test/` - fl_chart チャート Widget テスト
- `stale-state-guard/` - キャッシュ陳腐化バグ防止
- `maestro-qa/` - Maestro E2E テスト実行・レポート
- `bolt-firebase-tdd/` - Bolt for JS on Firebase の TDD パターン
- `skill-creator/` - 新規スキル作成ガイド

### Hooks (`hooks/`)
- `check-diff-size.sh` - Stop hook: 大規模差分検知 → Gemini レビュー促進
- `wave-guardrail.sh` - Stop hook: Wave ガードレール

### 共有メモリ (`shared-memory/`)
- `flutter-patterns.md` - Flutter 開発パターン記録（エージェント間で共有）
- `maestro-patterns.md` - Maestro E2E テストパターン記録

### テストランナースクリプト (`scripts/`)
- `flutter-test-runner.sh` - Flutter テスト実行 + サマリー出力（許可プロンプト1回で完結）
- `maestro-test-runner.sh` - Maestro E2E テスト実行 + サマリー出力（許可プロンプト1回で完結）

### カスタムコマンド (`commands/`)
- `commit-push.md` - コミット&プッシュ実行コマンド
- `review.md` - コードレビュー実行コマンド

### ガイド・テンプレート
- `settings_guide.md` - settings.json の詳しい説明
- `prompt_templates.md` - よく使うプロンプト集

## 参考リンク

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Best Practices (Anthropic公式)](https://www.anthropic.com/engineering/claude-code-best-practices)
- [WantedlyのClaude Code活用事例](https://www.wantedly.com/companies/wantedly/post_articles/981006)
