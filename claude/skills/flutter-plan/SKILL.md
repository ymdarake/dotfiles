---
name: flutter-plan
description: |
  Flutter Layer-first DDDプロジェクトの機能実装前に、DDD影響分析と計画策定を行うスキル。
  変更対象のfeature・Domain Model・interfaceを特定し、レイヤー別タスクとテスト戦略を出力する。

  **手動発動条件:**
  - ユーザーが「計画して」「設計して」「影響分析して」「実装計画を立てて」等と依頼した場合
  - `/flutter-plan` で直接呼び出し

  **内部呼び出し:**
  - flutter-tdd-cycle スキルの最初のステップとして呼び出される
user_invocable: true
---

# Flutter Plan スキル

Layer-first DDD風アーキテクチャに基づくFlutterプロジェクトで、機能実装前のDDD影響分析と計画策定を行う。

## ワークフロー

### Step 1: 要求の理解

ユーザーの機能要求を確認し、不明点があれば質問する:
- 何を実現したいか（ユーザーストーリー）
- 既存機能の変更か新規機能か
- 優先度・制約事項

### Step 2: 既存構造の探索

`flutter-layer-first-architect` エージェントをTask toolで起動し、構造探索と分析を委譲する。
エージェントはDDDアーキテクチャの知識（依存ルール、Resultパターン、interface設計原則）を持っており、
アーキテクチャ観点を踏まえた分析結果を返す。

```
Task tool → flutter-layer-first-architect エージェント:
"以下の機能要求に対して、プロジェクトの既存構造を探索し、影響分析を行ってください。

機能要求: <ユーザーの要求>

分析してほしいこと:
1. lib/domain/ 以下のfeature一覧とinterface定義
2. lib/use_case/ 以下の既存Service実装
3. lib/ui/page/ 以下の関連画面
4. lib/infrastructure/ 以下のデータアクセス実装
5. test/ 以下の既存テスト状況
6. 変更・新規作成が必要なファイルの特定
7. 既存interfaceへの破壊的変更の有無
8. cross-featureの依存関係（該当する場合）"
```

エージェントの分析結果を受け取り、Step 3 の計画出力に活用する。

### Step 3: 影響分析

flutter-layer-first-architect の分析結果を基に、変更計画をまとめる:

- **新規feature追加**: domain → use_case → infrastructure → ui の順でファイルを列挙
- **既存feature変更**: 既存interfaceへの影響範囲を特定（破壊的変更の有無）
- **cross-feature**: 複数featureにまたがる場合、依存関係を明示

### Step 4: Gemini相談（オプション）

設計判断に迷う場合、Geminiに相談する:

```
mcp__gemini-cli__chat(
  prompt: "Flutter Layer-first DDDアーキテクチャで以下の機能を実装します。設計方針についてアドバイスをください。\n\n<機能要求と現状の分析結果>",
  model: "gemini-3-pro-preview"
)
```

### Step 5: 計画出力

以下のテンプレートに従って計画を出力する。

**重要**: 計画はコンソール表示に加えて、プロジェクトルートに `docs/design/current_plan.md` として書き出す。
後続フェーズ（flutter-unit-test エージェント等）がこのファイルを読み込み、テスト対象や設計方針のコンテキストを正確に取得できるようにする。

## 出力テンプレート

```markdown
## 機能概要

<ユーザーの機能要求を1-2文で要約>

## 影響分析

### 変更対象

| レイヤー | ファイル | 変更種別 | 概要 |
|----------|----------|----------|------|
| domain | lib/domain/<feature>/model.dart | 新規/変更 | ... |
| domain | lib/domain/<feature>/service.dart | 新規/変更 | ... |
| domain | lib/domain/<feature>/repository.dart | 新規/変更 | ... |
| use_case | lib/use_case/<feature>/..._impl.dart | 新規/変更 | ... |
| infrastructure | lib/infrastructure/<feature>/... | 新規/変更 | ... |
| ui | lib/ui/page/<feature>/..._page.dart | 新規/変更 | ... |
| ui | lib/ui/page/<feature>/..._view_model.dart | 新規/変更 | ... |

### 依存関係への影響

- 既存interfaceの破壊的変更: あり/なし
- 影響を受ける他のfeature: <一覧>
- DI設定の変更: 必要/不要

## レイヤー別タスク

### 1. Domain層

- [ ] model.dart: <Entity/ValueObjectの定義>
- [ ] service.dart: <Serviceインターフェースのメソッド追加>
- [ ] repository.dart: <Repositoryインターフェースのメソッド追加>
- [ ] エラー型の定義

### 2. Use Case層

- [ ] <feature>_service_impl.dart: <Serviceの実装>

### 3. Infrastructure層

- [ ] <具象実装ファイル>: <Repository実装>

### 4. UI層

- [ ] <feature>_page.dart: <画面の実装>
- [ ] <feature>_view_model.dart: <状態管理の実装>
- [ ] DI Provider の登録

## テスト戦略

### Unit Test

| テスト対象 | テストファイル | 主なテストケース |
|-----------|--------------|-----------------|
| ServiceImpl | test/use_case/<feature>/..._test.dart | Success/Failure各パターン |
| ViewModel | test/ui/page/<feature>/..._test.dart | 状態遷移テスト |
| Model | test/domain/<feature>/model_test.dart | バリデーション |

### Widget Test（UI変更を伴う場合）

| テスト対象 | テストファイル | 主なテストケース |
|-----------|--------------|-----------------|
| Page | test/ui/page/<feature>/..._page_test.dart | Widget描画・ユーザー操作 |
| Compound | test/ui/compound/..._test.dart | コンポーネント単体の描画 |

### E2E Test（必要な場合）

- 対象フロー: <Maestro Flow名>
- 必要なSemantics identifier: <一覧>

## 実装順序

1. Domain層 interface 作成（テスト可能にする基盤）
2. Unit Test 作成（Red: 失敗するテストを先に書く）
3. Use Case / Infrastructure 実装（Green: テストを通す）
4. UI層 実装
5. リファクタリング（Refactor）
6. E2E テスト（オプション）
```

## 注意事項

- 計画はあくまで**提案**であり、ユーザーの承認を得てから実装に進む
- プロジェクト固有のパス構造やパッケージに合わせて柔軟に調整する
- テスト戦略では TDD (Red-Green-Refactor) の順序を明示する
- 小さな変更（バグ修正、1メソッド追加等）には過剰な計画を出さない
