# プロジェクト設定

プロジェクト固有の設定として `.claude/project_instructions.md` または `.claude/CLAUDE.md` に配置するファイルです。

## Bashコマンド

```bash
npm run build          # プロジェクトをビルド
npm run dev            # 開発サーバーを起動
npm test               # テストを実行
npm run typecheck      # 型チェックを実行
npm run lint           # Lintを実行
```

## コアファイルとディレクトリ構造

- `src/` - ソースコード
- `tests/` - テストコード
- `docs/` - ドキュメント
- `config/` - 設定ファイル

## コーディングスタイル

- インデント: スペース2つ
- モジュール: ES modules (import/export) を使用
- インポート: 可能な限り分割代入を使用
- 関数名: camelCase
- 定数: UPPER_SNAKE_CASE
- コメントは日本語可

## テスト方針

- 新機能追加時はテストも追加
- テスト実行: `npm test`
- カバレッジ確認: `npm run coverage`

## Git運用

- ブランチ戦略: GitHub Flow
- コミットメッセージは日本語で記述
- gitmoji を使用する（:wrench:, :bug:, :sparkles: など）
- コミット前にテスト実行
- プルリクエストは詳細な説明を記載

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*
