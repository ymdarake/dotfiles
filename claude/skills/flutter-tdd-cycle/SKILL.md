---
name: flutter-tdd-cycle
description: |
  Flutter Layer-first DDDプロジェクトでTDD Red-Green-Refactorサイクルをオーケストレーションするスキル。
  計画策定→失敗テスト生成→最小実装→リファクタリング→E2E（オプション）→レビューの一連のフローを管理する。

  **手動発動条件:**
  - ユーザーが「TDDで実装して」「機能を追加して」「TDDサイクルで」等と依頼した場合
  - `/flutter-tdd-cycle` で直接呼び出し

  **注意:**
  - 小さなバグ修正や1メソッド追加にはこのスキルは過剰。直接実装で良い
  - サブエージェント起動でAPIコストが発生するため、適切な粒度で使用する
user_invocable: true
---

# Flutter TDD Cycle スキル

Layer-first DDD風アーキテクチャに基づくFlutterプロジェクトで、TDD Red-Green-Refactorサイクルを段階的に実行する。

## 前提条件

- Flutter プロジェクトであること
- `pubspec.yaml` に `flutter_test` と `mocktail` が含まれていること
- Layer-first DDD風のディレクトリ構造であること

## ワークフロー

### Phase 1: 計画 (Plan)

`/flutter-plan` スキルを内部的に実行し、DDD影響分析と実装計画を作成する。

1. ユーザーの機能要求を確認する
2. 対象プロジェクトの構造を探索する
3. 影響分析と計画を出力する
4. **ユーザーの承認を待つ** — 承認なしで次のフェーズに進まない

### Phase 2: Red (失敗するテストを書く)

`@flutter-unit-test` サブエージェントを起動し、テストを生成する。

```
Task tool → flutter-unit-test エージェント:
"<feature名>のユニットテストを生成してください。
テスト対象: <計画で特定したファイル一覧>
テスト観点: <計画のテスト戦略セクション>"
```

テスト生成後、失敗を確認する:

```bash
flutter test test/use_case/<feature>/
```

**ゲート条件**: テストが**失敗する**ことを確認する。すでにテストが通る場合は、テストが不十分か実装が既に存在する。

コミット（オプション）:
```
git commit -m "[TDD:Red] <feature>: 失敗するテストを追加"
```

### Phase 3: Green (テストを通す最小実装)

メインセッションで最小限の実装コードを書く。

実装順序（計画に従う）:
1. Domain層: model, interface の作成/更新
2. Use Case層: Service実装
3. Infrastructure層: Repository実装
4. UI層: ViewModel, Page
5. DI設定: Provider登録

各ステップで部分的にテストを実行し、進捗を確認する:

```bash
flutter test test/use_case/<feature>/
```

**ゲート条件**: すべてのテストが**成功する**ことを確認する。

コミット（オプション）:
```
git commit -m "[TDD:Green] <feature>: テストを通す最小実装"
```

### Phase 4: Refactor (コードを改善)

テストが通った状態でコードを改善する:

- DRY原則の適用（重複コードの抽出）
- 命名の改善
- 不要なコードの削除
- パフォーマンスの改善

改善後、テストが引き続き通ることを確認する:

```bash
flutter test
```

**ゲート条件**: 全テストが**成功する**ことを確認する。

コミット（オプション）:
```
git commit -m "[TDD:Refactor] <feature>: コード改善"
```

### Phase 5: レビュー

構造の正しさをE2Eの前に確認する（手戻りコスト削減のため）。

差分が大きい場合（100行以上）、`check-diff-size.sh` フックが自動的にGeminiコードレビューを発動する。

手動でレビューを実行する場合:

```
gemini-code-review スキルを実行（汎用コードレビュー）
flutter-ddd-review スキルを実行（DDDアーキテクチャレビュー）
```

**DDDアーキテクチャレビュー**: Layer-first DDD風アーキテクチャの依存方向・責務・Resultパターン・interface分離を検証する場合は `flutter-ddd-review` を使用する。

**ゲート条件**: レビュー指摘の修正が完了していること。構造違反が残った状態でE2Eに進まない。

### Phase 6: E2E テスト (オプション)

UI変更を伴う場合、構造確定後にE2Eテストを追加する。

```
Task tool → maestro-e2e エージェント:
"<feature名>のE2Eテストを作成してください。
対象画面: <計画で特定した画面>
テストシナリオ: <ユーザーストーリー>"
```

## フェーズゲート

各フェーズの完了条件を明確にし、条件を満たさない限り次のフェーズに進まない:

| フェーズ | 完了条件 | 未達の場合 |
|----------|----------|-----------|
| Plan | ユーザーが計画を承認 | 計画を修正して再提示 |
| Red | `flutter test` が失敗する | テストケースを見直す |
| Green | `flutter test` が成功する | 実装を修正する |
| Refactor | `flutter test` が成功する | 改善を取り消す |
| Review | レビュー指摘の修正完了 | 指摘箇所を修正する |
| E2E | Maestro テストが成功する | Flow/UIを修正する |

## TDDサイクルの中断・再開

各フェーズの完了をgitコミットで記録することで、中断後の再開時にどのフェーズにいるか判定できる:

```bash
# 最新のTDDコミットを確認
git log --oneline --grep="\[TDD:" -5
```

- `[TDD:Red]` が最新 → Green フェーズから再開
- `[TDD:Green]` が最新 → Refactor フェーズから再開
- `[TDD:Refactor]` が最新 → Review フェーズから再開
- `[TDD:Review]` が最新 → E2E または完了

## 注意事項

- **コスト意識**: サブエージェント起動にはAPIコストがかかる。小さな変更には直接実装を推奨
- **柔軟性**: すべてのフェーズを厳密に実行する必要はない。状況に応じてフェーズをスキップ可能
- **既存テスト**: テストが既に存在するfeatureへの変更では、まず既存テストが通ることを確認してからRedフェーズに入る
- **破壊的変更**: interfaceの変更を伴う場合、影響を受ける既存テストの更新も計画に含める
