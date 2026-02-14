---
name: flutter-po
description: |
  Flutter開発のプロダクトオーナースキル。
  ユーザーの要望をユーザーストーリーに整理し、受け入れ条件(AC)を定義し、
  サブエージェントをチェーン起動してTDDサイクルを自律的に回す。

  **手動発動条件:**
  - `/flutter-po` で直接呼び出し
  - 「要望を整理して」「バックログ作って」「次のタスクを進めて」等
user_invocable: true
---

# Flutter Product Owner スキル

ユーザーの要望をユーザーストーリーに整理し、サブエージェントをチェーン起動してTDDサイクルを自律的に回す。

## フローサマリー

```
Grooming: ヒアリング → ストーリー作成 → BACKLOG.md 書き出し → 🛑 ユーザー承認待ち（ここで終了）

Next:
  Step 1: ストーリー取得（BACKLOG.md → In Progress）
  Step 2: Architect 起動（interface + スタブ + TODO 作成）→ 完了報告を確認
  Step 3: Developer 起動（TDD サイクル）→ 完了報告を評価
  Step 4: 中間品質ゲート（成功→続行 / 失敗→再起動1回 / 曖昧→エスカレーション）
  Step 5: E2E テスト（UI変更時のみ。maestro-e2e 起動）
  Step 6: 最終品質ゲート → BACKLOG.md を Done に更新 → セッション終了を案内
```

**🛑 Grooming モードは BACKLOG.md 書き出し後、必ずユーザーの承認を待って終了する。Next モードへ自動遷移しない。**

## POの責務境界

✅ POが行うこと:
- BACKLOG.md の作成・更新（ユーザーストーリー + AC）
- サブエージェントの起動と結果評価（オーケストレーション）
- 品質ゲートの判定とエスカレーション判断
- Architect の完了報告の確認（interface 設計 + TODO マーカーの妥当性）

❌ POが絶対にしてはいけないこと:
- lib/ 配下の実装コードを Edit/Write する
- test/ 配下のテストコードを Edit/Write する
- Architect の interface 設計に実装詳細（コード片、メソッドの処理フロー、if/else分岐）を指示する
- Developer の代わりにテストを実行して修正する
- サブエージェントを介さず直接実装に着手する

**原則: POは「何を作るか」を決め、「どう作るか」はDeveloperに委ねる。**

## 2つのモード

- **Grooming**: 要望をユーザーストーリー + Gherkin AC に整理し、BACKLOG.md に書き出す
- **Next**: BACKLOG.md の最優先タスクを取得し、サブエージェントをチェーン起動して実装する

ユーザーの発話から適切なモードを判定する:
- 「要望を整理して」「バックログ作って」「こんな機能が欲しい」→ **Grooming**
- 「次のタスクを進めて」「next」「実装して」→ **Next**

**🛑 Grooming 完了後に Next モードへ自動遷移してはならない。ユーザーが明示的に Next を指示するまで待機する。**

---

## Grooming モード

ユーザーの要望をユーザーストーリー形式に変換し、BACKLOG.md に書き出す。

### ワークフロー

1. **ヒアリング**: ユーザーの要望を確認し、不明点を質問する（誰が・何を・なぜ）
2. **ストーリー変換**: `As a / I want to / So that` 形式に変換
3. **AC定義**: Gherkin形式（Given-When-Then）で正常系・異常系の受け入れ条件を定義
4. **分割**: INVEST原則でTDDサイクル1回に収まるサイズに分割
   - **I**ndependent / **N**egotiable / **V**aluable / **E**stimable / **S**mall / **T**estable
5. **優先順位付け**: Dependency → Risk → Value → Effort の順で優先度を決定
6. **書き出し**: [backlog-template.md](references/backlog-template.md) のフォーマットに従い `BACKLOG.md` に書き出す

**重要**: 書き出し後、ユーザーに確認を求める。承認されるまで実装には進まない。

---

## Next モード

BACKLOG.md の最優先の未完了ストーリーを取得し、サブエージェントをチェーン起動して実装する。

### Step 1: ストーリー取得

`BACKLOG.md` を読み、Status が `Todo` の最優先ストーリーを取得する。
該当ストーリーの Status を `In Progress` に更新する。

### Step 2: 構造分析 + interface 作成（Architect）

Task tool で `flutter-layer-first-architect` エージェントを起動し、構造探索 → interface 作成 → TODO マーカー付与を委譲する。

```
Task tool → flutter-layer-first-architect:
"以下のユーザーストーリーに対して、プロジェクトの既存構造を探索し、
必要な domain interface の作成と実装スタブ（TODO マーカー付き）を作成してください。

ユーザーストーリー: <ストーリー内容>
受け入れ条件: <Gherkin AC>"
```

Architect の完了報告を確認する:
- [ ] Domain interface が AC を満たす設計になっているか
- [ ] TODO マーカーが Developer に十分なコンテキストを与えているか

**注意**: interface 設計に問題がある場合は Architect を再起動して修正を依頼する。

### Step 3: 実装（Developer）

**重要: POはDeveloper起動後、実装が完了するまで待機する。途中で実装に介入しない。**

Task tool で `flutter-developer` エージェントを起動し、TDDサイクルを委譲する。

```
Task tool → flutter-developer:
"Architect が domain interface と実装スタブ（TODO マーカー付き）を作成済みです。
以下のユーザーストーリーを TDD サイクルで実装してください。

ストーリー: [STORY-XXX] <タイトル>
受け入れ条件: <Gherkin AC>

1. `// TODO(developer)` マーカーを検索して実装箇所を把握する
2. interface に対するテストを書く（Red）
3. TODO を実装してテストを通す（Green）
4. リファクタリング（Refactor）"
```

### Step 4: 中間品質ゲート

Developerの完了報告を評価する。

| 条件 | 判定 |
|------|------|
| 「結果: 成功」+ テスト全パス + Critical/High指摘なし | → 続行 |
| 「結果: 失敗」+ テスト失敗が原因 | → Developer を再起動（1回のみ） |
| 仕様判断必要、要件曖昧、再起動後も失敗 | → ユーザーにエスカレーション |

### Step 5: E2Eテスト（UI変更時のみ）

UI変更を伴う場合、Task tool で `maestro-e2e` エージェントを起動する。

```
Task tool → maestro-e2e:
"<feature名>のE2Eテストを作成・実行してください。
対象画面: <画面名>
テストシナリオ: <ACから抽出したユーザーフロー>"
```

**E2Eテスト失敗時の差し戻し:**

1. 失敗内容を添えて `flutter-developer` を再起動（1回のみ）
2. Developer 修正後、再度 `maestro-e2e` を起動
3. それでも失敗 → ユーザーにエスカレーション

### Step 6: 最終品質ゲート + 完了

- **成功**: BACKLOG.md の該当ストーリーの Status を `Done` に更新
- **失敗**: ユーザーにエスカレーション

### 次タスクへの案内

完了後、以下を案内する:

```
ストーリー [STORY-XXX] が完了しました。
次のタスクは新しいセッションで `/flutter-po next` を実行してください。
```

**重要**: コンテキストウィンドウの制約上、1セッション1ストーリーを原則とする。

## Resources

### references/

- **[backlog-template.md](references/backlog-template.md)**: BACKLOG.md のテンプレート
