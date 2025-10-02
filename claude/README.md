# Claude Code 設定ガイド

このディレクトリには、Claude Codeの設定ファイルのサンプルを配置しています。

## 初期設定

### 1. `.claude/` ディレクトリの作成

プロジェクトのルートディレクトリに `.claude/` ディレクトリを作成します：

```bash
mkdir -p .claude
```

### 2. 設定ファイルの配置

以下のファイルをプロジェクトの `.claude/` ディレクトリにコピーまたは作成します：

- `project_instructions.md` - プロジェクト固有の指示
- `ignore.txt` - Claude Codeに無視させるファイル/ディレクトリ
- `commands/` - カスタムスラッシュコマンド（オプション）

### 3. グローバル設定

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

## カスタムコマンド（上級者向け）

`.claude/commands/` ディレクトリにMarkdownファイルを配置すると、スラッシュコマンドとして使用できます。

例：`.claude/commands/review.md`
```markdown
このプロジェクトのコーディング規約に沿って、現在開いているファイルをレビューしてください。
```

使用方法：
```
/review
```

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

### ガイド・テンプレート
- `settings_guide.md` - settings.json の詳しい説明
- `prompt_templates.md` - よく使うプロンプト集

## 参考リンク

- [Claude Code Documentation](https://docs.claude.com/claude-code)
- [Claude Code Best Practices (Anthropic公式)](https://www.anthropic.com/engineering/claude-code-best-practices)
- [WantedlyのClaude Code活用事例](https://www.wantedly.com/companies/wantedly/post_articles/981006)
