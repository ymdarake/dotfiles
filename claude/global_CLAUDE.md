# グローバル設定

グローバル設定として `~/.config/claude-code/project_instructions.md` または `~/.claude/CLAUDE.md` に配置するファイルです。

## 基本方針

- **常に日本語で応答する**
- グローバル設定を優先し、プロジェクト固有の設定は最小限にする
- 人間が読みやすく簡潔な設定を心がける

## Git運用

### コミットメッセージ

- 日本語で記述
- gitmoji を使用する
  - `:wrench:` 設定変更
  - `:bug:` バグ修正
  - `:sparkles:` 新機能
  - `:recycle:` リファクタリング
  - `:memo:` ドキュメント
  - `:white_check_mark:` テスト追加
  - `:art:` コードフォーマット

### ワークフロー

- ブランチ戦略はプロジェクトに従う
- コミット前にテスト実行（該当する場合）
- プルリクエストには詳細な説明を記載

## コーディング方針

- 可読性を最優先
- コメントは日本語可
- 複雑なロジックには説明コメントを追加
- マジックナンバーは定数化
- ES modules (import/export) を優先
- 分割代入を積極的に使用

## テスト方針（プロジェクトによる）

- TDD (Test-Driven Development) を推奨
- 新機能追加時はテストも追加
- テストコードの有無はプロジェクトの判断に従う

## セキュリティ

- 秘密情報をコミットしない
- .envファイルは必ず.gitignoreに追加
- APIキーやトークンはコードに直接書かない

## その他

- READMEは常に最新に保つ
- 破壊的変更は明示的に文書化
- 設定は会話中に `# CLAUDE.md` で追加・改善していく

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices), [WantedlyのClaude Code活用](https://www.wantedly.com/companies/wantedly/post_articles/981006)*
