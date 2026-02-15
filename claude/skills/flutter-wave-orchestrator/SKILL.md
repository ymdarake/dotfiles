---
name: flutter-wave-orchestrator
description: |
  Flutter Layer-first DDDプロジェクトで複数ユーザーストーリーを Wave 方式で並列実装するオーケストレーションスキル。
  flutter-po の Wave モードから内部呼び出しされる。

  **内部呼び出し条件:**
  - flutter-po で複数ストーリー指定時（Wave モード発動時）
  - `/flutter-wave-orchestrator` で直接呼び出し

  **発動例:**
  - 「STORY-017, 018, 019 を並列で実装して」
  - 「Wave で複数ストーリーを進めて」
---

# Flutter Wave Orchestrator

複数の関連ユーザーストーリーを Wave（段階的並列実行）方式で実装するための進行管理スキル。
`flutter-layer-first-architect` に Wave 計画策定を委譲し、計画書に従って PO が実行をオーケストレーションする。

## エージェント名の対応

| 略称 | 正式なエージェント名（subagent_type） |
|------|--------------------------------------|
| Architect | `flutter-layer-first-architect` |
| Developer | `flutter-developer` |
| E2E | `maestro-e2e` |
| Plan | `Plan`（subagent_type: Plan） |

## フローサマリー

```
Phase 1: 影響分析（Plan × N ストーリー）
  → 各 docs/plans/STORY-XXX.md を生成

Phase 2: Wave 計画策定（flutter-layer-first-architect）
  → 全 Plan を読み、競合分析 + 共有 interface 特定 + Wave 分割
  → docs/plans/WAVE_{YYYYMMDD}.md に出力

Phase 3: Wave 実行（PO がオーケストレーション）
  → Wave 0: flutter-layer-first-architect が interface 定義 + スタブ実装
  → Wave 1+: flutter-developer が git worktree で並列実装
  → Wave N-1: 統合レビュー
  → Wave N: maestro-e2e
```

## 責務境界

**Orchestrator（このスキル）が行うこと:**
- 対象ストーリーの Plan 収集を PO に指示
- `flutter-layer-first-architect` への Wave 計画策定依頼プロンプトの提供
- 計画書に従った各 Wave の実行手順定義
- Wave 間の品質ゲート条件の定義

**Orchestrator がしないこと:**
- 競合分析や interface 特定（`flutter-layer-first-architect` の責務）
- 実装コードの編集（`flutter-developer` の責務）
- ビジネス判断（PO の責務）

---

## Phase 1: 影響分析

対象ストーリーごとに Plan エージェントを起動する。
既存の flutter-po Next モード Step 1.5 と同じ手順を繰り返す。

**並列起動可能**: 各ストーリーの Plan は独立しているため、Task tool で並列起動してよい。

```
対象ストーリーごとに:
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

PO が各出力を `docs/plans/STORY-XXX.md` に Write で保存する。

---

## Phase 2: Wave 計画策定（flutter-layer-first-architect）

全ストーリーの Plan が揃ったら、`flutter-layer-first-architect` に Wave 計画策定を委譲する。

`flutter-layer-first-architect` への依頼プロンプトは [architect-wave-planning.md](references/architect-wave-planning.md) を参照。

`flutter-layer-first-architect` の出力を PO が `docs/plans/WAVE_{YYYYMMDD}.md` に保存する。
計画書のフォーマットは [wave-plan-template.md](references/wave-plan-template.md) に従う。

### 計画書の確認ポイント

PO は以下を確認してから Phase 3 に進む:
- [ ] 全対象ストーリーが Wave に割り当てられているか
- [ ] 順序制約の理由が明確か
- [ ] Wave 0 の共有 interface が全ストーリーの AC をカバーしているか
- [ ] Git worktree 戦略が定義されているか

---

## Phase 3: Wave 実行

計画書に従い、PO が各 Wave を順次実行する。
各 Wave のサブエージェント起動プロンプトは [wave-prompts-template.md](references/wave-prompts-template.md) を参照。

### Wave 0: アーキテクチャ準備

`flutter-layer-first-architect` が自身の計画に基づき interface 定義 + スタブ実装を行う。

**品質ゲート（Wave 0 → Wave 1 の条件）:**
- [ ] `dart analyze` パス
- [ ] `flutter test` パス（既存テストの回帰なし）
- [ ] 共有 interface が定義済み
- [ ] 各ストーリー向けの TODO マーカーが配置済み
- [ ] master にコミット済み

### Wave 1+: 並列実装

**実行者: PO（セットアップ） → `flutter-developer`（実装）**

PO が git worktree をセットアップし、各 `flutter-developer` を Task tool で並列起動する。
（※ 複数の Task tool 呼び出しを1つのレスポンスに含めることで並列実行される）

```bash
# PO: worktree セットアップ（Wave 0 完了後、メインリポジトリで実行）
git worktree add ../<project>-story-xxx -b feature/story-xxx
(cd ../<project>-story-xxx && flutter pub get)
# ※ サブシェルで実行するためカレントディレクトリは変わらない
# ※ クリーンアップはここではやらない。Wave N-1 のマージ完了後に行う
```

**品質ゲート（各 Wave → 次 Wave の条件）:**
- [ ] 各 worktree で `dart analyze` パス
- [ ] 各 worktree で `flutter test` パス
- [ ] `flutter-developer` の完了報告に Critical/High 指摘なし

### Wave N-1: 統合マージ + レビュー

**実行者: PO（マージ + クリーンアップ）**

並列作業のブランチを順次マージし、統合状態で品質確認する。
**⚠️ worktree の削除は必ず全マージ完了後に行うこと。未マージの worktree を削除するとコミットが失われる。**

```bash
# Step 1: 各 feature ブランチを master に squash merge（計画書のマージ順序に従う）
git merge --squash feature/story-XXX
git commit -m ":sparkles: [STORY-XXX] <タイトル>"

git merge --squash feature/story-YYY
git commit -m ":sparkles: [STORY-YYY] <タイトル>"

# Step 2: 統合テスト
flutter pub get && dart analyze && flutter test

# Step 3: worktree クリーンアップ（Step 1, 2 が全て成功した後のみ）
git worktree remove ../<project>-story-xxx
git worktree remove ../<project>-story-yyy
```

コンフリクト発生時は `flutter-developer` を起動して解決する。

**統合品質ゲート:**
- [ ] `dart analyze` パス
- [ ] `flutter test` 全パス
- [ ] Gemini コードレビュー実行
- [ ] 重複コード・不整合のチェック

### Wave N: Maestro E2E

UI 変更を伴う場合、maestro-e2e エージェントで E2E テストを実行する。

---

## エラーハンドリング

### `flutter-developer` が設計不備を検知した場合

Wave 1+ の実装中に「共有 interface が不足」と判明した場合:

1. `flutter-developer` が不足内容を報告して停止
2. PO が `flutter-layer-first-architect` を再起動し、interface 追加を依頼
3. `flutter-layer-first-architect` が修正を master にコミット
4. 各 worktree で `git rebase master` 後、`flutter-developer` を再開

### Wave 間の失敗

品質ゲートが通らない場合:

| 状況 | 対応 |
|------|------|
| テスト失敗（単純） | `flutter-developer` を再起動（1回のみ） |
| 設計不備 | `flutter-layer-first-architect` に差し戻し |
| 仕様曖昧 | ユーザーにエスカレーション |

## Resources

### references/

- **[architect-wave-planning.md](references/architect-wave-planning.md)**: Architect への Wave 計画策定依頼プロンプト
- **[wave-plan-template.md](references/wave-plan-template.md)**: Wave 計画書のフォーマット
- **[wave-prompts-template.md](references/wave-prompts-template.md)**: 各 Wave のサブエージェント起動プロンプト集
