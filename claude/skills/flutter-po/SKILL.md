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

Plan: BACKLOG.md → 対象ストーリー特定 → Plan エージェント並列起動 → doc/plan/ に保存 → 🛑 終了

Next:
  Step 1: ストーリー取得（BACKLOG.md → In Progress）
  Step 1.5: 影響分析（Plan エージェント → 事実の探索と整理 → doc/plan/ に保存）
  Step 2: Architect 起動（影響分析を基に設計判断 + interface + スタブ + TODO 作成）→ 完了報告を確認
  Step 3: Developer 起動（TDD サイクル）→ 完了報告を評価
  Step 4: 中間品質ゲート（成功→続行 / 失敗→再起動1回 / 曖昧→エスカレーション）
  Step 5: E2E テスト（UI変更時のみ。maestro-e2e 起動）
  Step 6: 最終品質ゲート → ストーリーをスプリントファイルにアーカイブ → セッション終了を案内
```

**🛑 Grooming モードは BACKLOG.md 書き出し後、必ずユーザーの承認を待って終了する。Next モードへ自動遷移しない。**

## POの責務境界

✅ POが行うこと:
- BACKLOG.md の作成・更新（ユーザーストーリー + AC）
- サブエージェントの起動と結果評価（オーケストレーション）
- 品質ゲートの判定とエスカレーション判断
- Plan エージェントの出力確認（影響範囲が妥当か、漏れがないか）
- Architect の完了報告の確認（interface 設計 + TODO マーカーの妥当性）

❌ POが絶対にしてはいけないこと:
- lib/ 配下の実装コードを Edit/Write する
- test/ 配下のテストコードを Edit/Write する
- Architect の interface 設計に実装詳細（コード片、メソッドの処理フロー、if/else分岐）を指示する
- Developer の代わりにテストを実行して修正する
- サブエージェントを介さず直接実装に着手する

**原則: POは「何を作るか」を決め、「どう作るか」はDeveloperに委ねる。**

## 4つのモード

- **Grooming**: 要望をユーザーストーリー + Gherkin AC に整理し、BACKLOG.md に書き出す
- **Plan**: BACKLOG.md の対象ストーリーの影響分析を一括生成し、doc/plan/ に保存する
- **Next**: BACKLOG.md の最優先タスクを取得し、サブエージェントをチェーン起動して実装する
- **Wave**: 複数ストーリーを Wave 方式で並列実装する（flutter-wave-orchestrator を内部呼び出し）

ユーザーの発話から適切なモードを判定する:
- 「要望を整理して」「バックログ作って」「こんな機能が欲しい」→ **Grooming**
- 「計画だけ先に」「Plan を作って」「影響分析して」→ **Plan**
- 「次のタスクを進めて」「next」「実装して」→ **Next**
- 「STORY-017, 018, 019 を並列で」「Wave で進めて」「複数ストーリーを実装」→ **Wave**

**🛑 Grooming 完了後に Next / Wave / Plan モードへ自動遷移してはならない。ユーザーが明示的に指示するまで待機する。**

---

## Grooming モード

ユーザーの要望をユーザーストーリー形式に変換し、BACKLOG.md に書き出す。

### スプリント管理

BACKLOG.md の `Current Sprint` を確認する。

- スプリントが未設定の場合 → ユーザーにスプリント番号を確認して設定する
- ユーザーが「新しいスプリントを開始して」と言った場合 → スプリント番号をインクリメントする

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

## Plan モード

BACKLOG.md の対象ストーリーの影響分析（doc/plan/STORY-XXX.md）を一括生成する。
実装には進まない。Next / Wave の事前準備として使用する。

### ワークフロー

1. BACKLOG.md を読み、対象ストーリーを特定する
   - ユーザーがストーリー ID を指定した場合 → 指定されたストーリーのみ
   - 指定なしの場合 → Current Sprint 内の Status が `Todo` の全ストーリー
2. 既に doc/plan/STORY-XXX.md が存在するストーリーはスキップする（上書きしない）
   - ユーザーが明示的に再生成を指示した場合は上書きする
3. 対象ストーリーごとに Task tool で Plan エージェント（subagent_type: Plan）を並列起動する
   （プロンプトは Next モード Step 1.5 と同一）
4. 各 Plan エージェントの出力を PO が doc/plan/STORY-XXX.md に Write で保存する（Plan エージェントは Write 権限を持たないため）
5. 全ストーリーの Plan 完了後、一覧を表示して終了する

🛑 Plan モード完了後、Next / Wave モードへ自動遷移しない。

---

## Next モード

BACKLOG.md の最優先の未完了ストーリーを取得し、サブエージェントをチェーン起動して実装する。

### Step 1: ストーリー取得

`BACKLOG.md` を読み、Status が `Todo` の最優先ストーリーを取得する。
該当ストーリーの Status を `In Progress` に更新する。

### Step 1.5: 影響分析（Plan）

Task tool で `Plan` エージェント（`subagent_type: Plan`）を起動し、
コードベースの深い探索と影響分析を行わせる。

**Plan の責務は「事実の探索と整理」に限定する。設計判断は Architect の責務。**

Plan の出力は `doc/plan/STORY-XXX.md` にファイルとして保存する。
これにより Architect / Developer がコンテキストに依存せず `Read` で参照できる。

```
Task tool → Plan:
"以下のユーザーストーリーに対して、コードベースを探索し影響分析を行ってください。
設計判断は不要です。事実の収集と整理に徹してください。

プロジェクトルート: <path>

ストーリー: [STORY-XXX] <タイトル>
受け入れ条件: <Gherkin AC>
Technical Notes: <BACKLOG.md の Technical Notes>

以下を出力してください:
1. 関連ファイル一覧（パス + 該当行番号 + 現在の役割・内容の要約）
2. 既存の設計パターン（関連箇所で使われている Riverpod パターン、レイヤー構成等）
3. 既存テストの現状（関連テストファイル + カバー範囲）
4. AC 実現に必要な変更箇所の候補（何を変えるかの事実列挙。どう変えるかは書かない）"
```

Plan エージェントの出力を PO が `doc/plan/STORY-XXX.md` に Write で保存する
（Plan エージェントは Write ツールを持たないため、PO が代行する）。

保存後、影響範囲の妥当性・漏れがないかをチェックしてから Step 2 に進む。

**スキップ条件**（以下の場合は Step 1.5 を省略して Step 2 に進む）:
- `doc/plan/STORY-XXX.md` が既に存在する場合（Plan モードで生成済み）
- E2E フローの修正のみ（lib/ 変更なし）
- 単純な1ファイル変更
- ユーザーが既に詳細な計画を提供済み

### Step 2: 構造分析 + interface 作成（Architect）

Task tool で `flutter-layer-first-architect` エージェントを起動し、Plan の影響分析を基に設計判断 → interface 作成 → TODO マーカー付与を委譲する。

```
Task tool → flutter-layer-first-architect:
"Plan エージェントが影響分析を作成済みです。
まず doc/plan/STORY-XXX.md を Read で読み込み、
影響分析の内容を踏まえて設計判断を行い、必要な domain interface の作成と実装スタブ（TODO マーカー付き）を作成してください。

## 影響分析ファイル
doc/plan/STORY-XXX.md

## ユーザーストーリー
<ストーリー内容>

## 受け入れ条件
<Gherkin AC>"
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

影響分析: doc/plan/STORY-XXX.md
（実装判断に迷った場合、影響分析の内容を参考にしてください）

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

- **成功**:
  1. BACKLOG.md の `Current Sprint` からスプリント番号を取得する
  2. `doc/iteration/sprint-N.md` が存在しなければ [iteration-template.md](references/iteration-template.md) から作成する
  3. 完了ストーリーのセクション全体（User Story + AC + Technical Notes）を `doc/iteration/sprint-N.md` に追記する
     - **完了日** を付与する（例: `**完了日**: 2026-02-14`）
  4. BACKLOG.md から該当ストーリーのセクションを削除する
- **失敗**: ユーザーにエスカレーション

### 次タスクへの案内

完了後、以下を案内する:

```
ストーリー [STORY-XXX] が完了しました。（Sprint N にアーカイブ済み）
次のタスクは新しいセッションで `/flutter-po next` を実行してください。
```

**重要**: コンテキストウィンドウの制約上、1セッション1ストーリーを原則とする。

---

## Wave モード

複数ストーリーを Wave 方式で並列実装する。flutter-wave-orchestrator スキルを内部呼び出しする。

### 発動条件

以下のいずれかに該当する場合に Wave モードを使用する:
- ユーザーが複数ストーリー ID を指定した（例: `STORY-017, 018, 019`）
- 「並列で実装」「Wave で」と指示された
- BACKLOG.md で依存関係のない複数ストーリーがあり、ユーザーが並列実装を了承

### ワークフロー

flutter-wave-orchestrator の手順に従い、PO がオーケストレーションする:

1. **Phase 1**: 対象ストーリーごとに Plan エージェントを並列起動 → `doc/plan/STORY-XXX.md` に保存
   - Plan モードで事前生成済みの場合、Phase 1 をスキップする。
2. **Phase 2**: Architect に全 Plan を渡して Wave 計画策定を依頼 → `doc/plan/WAVE_{YYYYMMDD}.md` に保存
3. **Phase 3**: 計画書に従い各 Wave を順次実行
   - Wave 0: `flutter-layer-first-architect` が interface 定義 + スタブ
   - Wave 1+: PO が tmux で worktree ごとに `claude --agent flutter-developer` を起動。
     INSTRUCTION.md → report.md → tmux send-keys によるファイルベースメッセージングで管理。
     （Task tool ではなく独立 Claude インスタンスで実行。詳細は flutter-wave-orchestrator を参照）
   - Wave N-1: 統合マージ + レビュー
   - Wave N: Maestro E2E（UI 変更時）
4. **完了**: 全ストーリーを `doc/iteration/sprint-N.md` にアーカイブ

**詳細は flutter-wave-orchestrator スキルの SKILL.md を参照。**

### Wave vs Next の判断基準

| 条件 | モード |
|------|--------|
| ストーリー 1 つ | Next |
| ストーリー 2+ で競合なし | Wave（並列効率が高い） |
| ストーリー 2+ で強い依存 | Next を順次実行（Wave の効果が薄い） |

## Resources

### references/

- **[backlog-template.md](references/backlog-template.md)**: BACKLOG.md のテンプレート
- **[iteration-template.md](references/iteration-template.md)**: スプリントアーカイブファイルのテンプレート
