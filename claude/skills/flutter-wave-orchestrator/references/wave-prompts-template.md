# Wave サブエージェント起動プロンプト集

各 Wave で PO が使用するサブエージェント起動プロンプトのテンプレート。

## Wave 0: Architect 起動

```
Task tool → flutter-layer-first-architect:
"Wave 計画書に基づき、共有 interface の定義とスタブ実装を行ってください。

## Wave 計画書
docs/plans/WAVE_{YYYYMMDD}.md（※ {YYYYMMDD} は実際の日付に置換）

## 実施内容
計画書の「Wave 0: アーキテクチャ準備」セクションの Tasks を全て実施してください。

## 注意事項
- 各ストーリーの実装箇所に `// TODO(developer): STORY-XXX <説明>` マーカーを配置
- スタブは `throw UnimplementedError()` で実装
- 新しいパッケージ依存を追加した場合は `flutter pub get` を実行
- 既存テストを壊さないこと（`flutter test` で確認）"
```

## Wave 1+: Developer 並列起動

各ストーリーごとに独立した Task tool で起動する。

```
Task tool → flutter-developer:
"以下のユーザーストーリーを TDD サイクルで実装してください。

## 作業ディレクトリ
../<project>-story-XXX（git worktree）

## ストーリー
[STORY-XXX] <タイトル>

## 受け入れ条件
<Gherkin AC>

## 影響分析
docs/plans/STORY-XXX.md を参照

## Wave 計画書
docs/plans/WAVE_{YYYYMMDD}.md（※ {YYYYMMDD} は実際の日付に置換） の、あなたが担当する Wave セクションを参照

## 実装手順
1. `// TODO(developer): STORY-XXX` マーカーを検索して実装箇所を把握
2. interface に対するテストを書く（Red）
3. TODO を実装してテストを通す（Green）
4. リファクタリング（Refactor）
5. `dart analyze` + `flutter test` で品質確認

## 注意事項
- ⚠️ 全てのファイル読み込み・編集・コマンド実行は、必ず指定された作業ディレクトリ内で行うこと。メインリポジトリのファイルには一切触れない
- このストーリーのスコープ外の変更はしない
- 共有 interface に不足がある場合は、実装せず報告して停止"
```

## Wave N-1: 統合マージ + レビュー

**実行者: PO（マージ + クリーンアップ）**

PO が直接実行する手順。マージ → テスト → クリーンアップの順序を厳守する。

```bash
# マージ順序は Wave 計画書の「Git Worktree 戦略」に従う
# ⚠️ 重要: worktree の削除は必ず全マージ + テスト完了後に行うこと

# Step 1: 各 feature ブランチを master に squash merge
git merge --squash feature/story-xxx
git commit -m ":sparkles: [STORY-XXX] <タイトル>"

git merge --squash feature/story-yyy
git commit -m ":sparkles: [STORY-YYY] <タイトル>"

# Step 2: 統合テスト
flutter pub get && dart analyze && flutter test

# Step 3: worktree クリーンアップ（Step 1, 2 が全て成功した後のみ）
git worktree remove ../<project>-story-xxx
git worktree remove ../<project>-story-yyy
```

コンフリクト発生時は `flutter-developer` を起動して解決:

```
Task tool → flutter-developer:
"git merge でコンフリクトが発生しました。以下のファイルのコンフリクトを解決してください。

## コンフリクトファイル
<git status の出力>

## 解決方針
Wave 計画書の順序制約に従い、両方の変更を統合してください。
docs/plans/WAVE_{YYYYMMDD}.md（※ {YYYYMMDD} は実際の日付に置換） を参照。

## 解決後
- `dart analyze` + `flutter test` で品質確認
- コンフリクトマーカーが残っていないこと"
```

## Wave N: E2E テスト

```
Task tool → maestro-e2e:
"Wave 実装完了後の E2E テストを実行してください。

## 対象ストーリー
- [STORY-XXX] <タイトル>
- [STORY-YYY] <タイトル>

## テストシナリオ
各ストーリーの AC から抽出した主要ユーザーフロー:
1. <シナリオ 1>
2. <シナリオ 2>

## 既存フロー回帰
既存の Maestro Flow も全て実行して回帰テストを行うこと"
```
