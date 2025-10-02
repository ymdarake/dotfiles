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

### 設計原則

- **インターフェースに対してプログラミングする** - 具象クラスではなく抽象に依存
- **単一責任原則 (SRP)** - 1つのクラス/関数は1つの責任のみを持つ
- **DRY原則 (Don't Repeat Yourself)** - コードの重複を避け、再利用可能に設計
- 依存性注入を活用し、テスタビリティを確保

### コードスタイル

- 可読性を最優先
- コメントは日本語可
- 複雑なロジックには説明コメントを追加
- マジックナンバーは定数化
- ES modules (import/export) を優先
- 分割代入を積極的に使用

## テスト方針

### TDD (Test-Driven Development)

- **Red-Green-Refactor サイクル**を基本とする
  1. **Red**: まず失敗するテストを書く
  2. **Green**: テストを通す最小限の実装
  3. **Refactor**: コードを改善（DRY原則、設計原則を適用）
- 新機能実装時は必ずテストから書き始める
- テストがないコードは追加しない（レガシーコード対応を除く）

### テストの粒度

- ユニットテスト: 個々の関数・クラスの振る舞いを検証
- 統合テスト: コンポーネント間の連携を検証
- E2Eテスト: ユーザーシナリオ全体を検証
- テストカバレッジ80%以上を目標（プロジェクトによる）

## セキュリティ

- 秘密情報をコミットしない
- .envファイルは必ず.gitignoreに追加
- APIキーやトークンはコードに直接書かない

## プロジェクト構造の把握

- まず README.md を確認する
- package.json、go.mod、Cargo.toml 等から技術スタックを把握
- ディレクトリ構造を ls や tree で確認
- .claude/CLAUDE.md にプロジェクト固有の情報を確認

## よく使うBashコマンド

```bash
ls -la                  # ファイル一覧を詳細表示
git status              # Gitの状態確認
git log --oneline -10   # 最近のコミット履歴
cat README.md           # READMEを確認
```

## その他

- READMEは常に最新に保つ
- 破壊的変更は明示的に文書化
- 設定は会話中に `# CLAUDE.md` で追加・改善していく

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices), [WantedlyのClaude Code活用](https://www.wantedly.com/companies/wantedly/post_articles/981006)*
