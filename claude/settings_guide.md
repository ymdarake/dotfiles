# Claude Code 権限設定ガイド (settings.json)

## settings.json とは？

Claude Code の**権限設定**を管理するファイルです。事前に許可した操作は、確認なしで実行できるようになります。

## なぜ必要？

Claude Code はデフォルトで安全性を重視し、ファイル読み取りやコマンド実行のたびに許可を求めます。
頻繁に使う操作を事前許可しておくと、作業がスムーズになります。

## 配置場所

```bash
.claude/settings.json  # プロジェクトごとの設定
```

## 設定方法

### 方法1: 対話的に設定（初心者におすすめ）

```bash
/permissions
```

このコマンドで現在の権限設定を確認・変更できます。Claude が対話形式で案内してくれます。

### 方法2: サンプルをコピーして使う

```bash
# このリポジトリのサンプルをコピー
cp claude/settings.json.sample .claude/settings.json

# 必要に応じて編集
vim .claude/settings.json
```

### 方法3: 手動で作成

`.claude/settings.json` を以下の形式で作成：

```json
{
  "permissionSettings": {
    "alwaysAllow": {
      "Read": ["**/*.ts", "**/*.js"],
      "Bash": ["git status:*", "npm test:*"]
    }
  }
}
```

## 設定項目の説明

### Read（ファイル読み取り）

Claude がファイルを読み取る際の許可設定。

```json
"Read": [
  "**/*.ts",           // すべてのTypeScriptファイル
  "src/**",            // srcディレクトリ内のすべて
  "**/package.json",   // すべてのpackage.json
  "README.md"          // ルートのREADME.md
]
```

**パターンの書き方：**
- `**` : すべてのディレクトリ
- `*` : 任意の文字列
- `*.ts` : TypeScriptファイル
- `src/**` : srcディレクトリ以下すべて

### Bash（コマンド実行）

シェルコマンドの実行許可設定。

```json
"Bash": [
  "git status:*",      // git status系コマンド
  "git diff:*",        // git diff系コマンド
  "npm test:*",        // npm test系コマンド
  "npm run:*"          // npm run系コマンド
]
```

**書き方：**
- `コマンド名:*` の形式
- `:*` は「すべてのオプション・引数を許可」の意味

## よくある設定例

### パターン1: 開発で便利な設定

```json
{
  "permissionSettings": {
    "alwaysAllow": {
      "Read": [
        "**/*.ts",
        "**/*.js",
        "**/package.json",
        "**/README.md"
      ],
      "Bash": [
        "git status:*",
        "git diff:*",
        "git log:*",
        "npm run:*",
        "npm test:*"
      ]
    }
  }
}
```

**用途:** TypeScript/JavaScript プロジェクトでの日常的な開発

### パターン2: Go言語プロジェクト

```json
{
  "permissionSettings": {
    "alwaysAllow": {
      "Read": [
        "**/*.go",
        "**/go.mod",
        "**/go.sum"
      ],
      "Bash": [
        "git status:*",
        "go test:*",
        "go build:*"
      ]
    }
  }
}
```

### パターン3: セキュアな設定（最小権限）

```json
{
  "permissionSettings": {
    "alwaysAllow": {
      "Read": ["src/**"],
      "Bash": ["git status:*"]
    }
  }
}
```

**用途:** セキュリティを重視し、必要最小限の権限のみ

### パターン4: すべて許可（開発環境のみ推奨）

```json
{
  "permissionSettings": {
    "alwaysAllow": {
      "Read": ["**"],
      "Bash": ["*"]
    }
  }
}
```

⚠️ **注意:** 本番環境や機密情報を含むプロジェクトでは非推奨

## セキュリティのベストプラクティス

### ✅ 許可すべきもの

- ソースコード (`src/**`, `**/*.ts` など)
- 設定ファイル (`package.json`, `tsconfig.json` など)
- ドキュメント (`**/*.md`)
- 読み取り専用のGitコマンド (`git status`, `git log` など)
- テスト実行コマンド (`npm test`, `go test` など)

### ❌ 許可すべきでないもの

- 環境変数ファイル (`.env`, `.env.local`)
- 秘密鍵・認証情報 (`id_rsa`, `credentials.json`)
- データベースファイル (`*.db`, `*.sqlite`)
- 破壊的なコマンド (`rm -rf`, `git push --force`)

## 設定のコツ

### 1. 段階的に許可する

```
最初は制限的 → 不便を感じたら追加 → 徐々に最適化
```

### 2. プロジェクトごとに調整

- Webアプリ: `**/*.ts`, `**/*.tsx`, `npm run:*`
- CLIツール: `**/*.go`, `go build:*`
- Python: `**/*.py`, `pytest:*`

### 3. チーム開発の場合

- `.claude/settings.json` をgit管理に含める
- チーム共通の安全な設定を共有
- 個人的な設定は `.gitignore` に追加

## 確認・管理コマンド

```bash
# 現在の設定を確認
/permissions

# 設定ファイルの場所を確認
ls -la .claude/settings.json

# 設定を編集
vim .claude/settings.json
```

## トラブルシューティング

### 設定が反映されない

1. ファイル名が正しいか確認: `.claude/settings.json`
2. JSON形式が正しいか確認（カンマ、括弧など）
3. Claude Code を再起動

### 毎回聞かれる操作を見つけたら

1. 操作時に表示される内容を確認
2. パターンを `settings.json` に追加
3. 次回から自動許可される

### 誤って広い権限を与えてしまった

1. `.claude/settings.json` を編集
2. 不要な許可を削除
3. 保存して Claude Code を再起動

## 実践的な使い方

### ステップ1: サンプルからスタート

```bash
cp claude/settings.json.sample .claude/settings.json
```

### ステップ2: プロジェクトに合わせて調整

使わない言語の設定を削除し、必要な設定を追加。

### ステップ3: 運用しながら改善

作業中に「毎回許可を求められて面倒」と感じたら、その操作を追加。

## まとめ

- `settings.json` で事前許可すると作業効率UP
- セキュリティとのバランスが重要
- 段階的に最適化していくのがおすすめ
- 困ったら `/permissions` コマンドで確認

---

*参考: [Claude Code Documentation](https://docs.claude.com/claude-code)*
