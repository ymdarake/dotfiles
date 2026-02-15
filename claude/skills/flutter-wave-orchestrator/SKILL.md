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
  → Wave 1+: tmux で worktree ごとに Claude --agent flutter-developer を起動（メッセージングモデル）
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

### Wave 1+: 並列実装（tmux メッセージングモデル）

**実行者: PO（セットアップ + 待機） → `flutter-developer`（各 worktree で自律実装）**

#### Why tmux?
Task tool のサブエージェントは cwd がメインプロジェクトに固定され、worktree 内のファイルに
パーミッションパターンが届かない。tmux で独立した Claude インスタンスを起動することで解決する。

#### Step 1: worktree セットアップ

```bash
# PO: worktree セットアップ（Wave 0 完了後、メインリポジトリで実行）
git worktree add ../<project>-story-xxx -b feature/story-xxx
cp -r .claude ../<project>-story-xxx/
(cd ../<project>-story-xxx && flutter pub get)
# ※ サブシェルで実行するためカレントディレクトリは変わらない
# ※ .claude/ を必ずコピーする（worktree には自動コピーされない）
# ※ クリーンアップはここではやらない。Wave N-1 のマージ完了後に行う
```

#### Step 2: INSTRUCTION.md の配置

PO が各 worktree ルートに INSTRUCTION.md を Write で作成する。
フォーマット: [instruction-template.md](references/instruction-template.md)

PO の tmux ペイン ID を含める（Developer が完了通知を送る宛先）。
PO は自身の tmux ペイン ID を以下で取得する:
```bash
tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
```

#### Step 3: tmux で Developer 起動

PO が tmux で新ウィンドウを作成し、Claude CLI を起動する。

```bash
tmux new-window -n "story-xxx" -c "../<project>-story-xxx" \
  "claude --agent flutter-developer \
    --permission-mode bypassPermissions \
    'INSTRUCTION.md を読んで指示に従って TDD サイクルで実装してください' \
    2>&1 | tee /tmp/claude-story-xxx.log; \
  touch /tmp/claude-story-xxx-exited"
```

| オプション | 値 | 理由 |
|-----------|-----|------|
| `--agent` | `flutter-developer` | Developer エージェント定義を使用 |
| `--permission-mode` | `bypassPermissions` | worktree 内で自律実行（対話承認不可のため必須） |
| (対話モード) | `-p` なし | スキル（flutter-tdd-cycle 等）が使える。プロセス完了時に tmux send-keys で PO に通知 |

#### Step 4: 完了報告の受信（イベント駆動）

Developer は実装完了時に:
1. worktree ルートに `report.md` を Write（フォーマット: [report-template.md](references/report-template.md)）
2. tmux send-keys で PO に通知:
```bash
# ベストプラクティス: C-c で行クリア → -l でリテラル送信 → Enter
tmux send-keys -t <PO-pane> C-c
tmux send-keys -t <PO-pane> -l '[STORY-XXX] 完了。Read <absolute-path>/report.md'
tmux send-keys -t <PO-pane> Enter
```

**tmux send-keys の注意点:**
- `C-c` を先に送って PO のプロンプト行をクリアする（既存入力があると混ざるため）
- `-l` フラグでリテラル送信（特殊文字の解釈を防ぐ）
- ターゲットは `session:window.pane` 形式で正確に指定（INSTRUCTION.md に記載）
- PO が処理中の場合、キー入力はバッファされ、処理完了後に受信される

PO は通知を「ユーザー入力」として受信し、report.md を Read して品質ゲート判定する。
ポーリング不要。

**フォールバック**: Developer が通知を送れなかった場合（クラッシュ等）:
- `/tmp/claude-story-xxx-exited` の存在で異常終了を検知
- `/tmp/claude-story-xxx.log` でエラー原因を確認

#### 品質ゲート（各 Wave → 次 Wave の条件）

report.md の YAML Frontmatter で判定:

- [ ] `result: success`
- [ ] `dart_analyze: pass`
- [ ] `flutter_test: pass`
- [ ] `critical_issues: 0`
- [ ] `high_issues: 0`
- [ ] `interface_insufficient: false`

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

### Developer プロセスが異常終了した場合

1. `/tmp/claude-story-xxx-exited` が存在するが tmux send-keys 通知が来ない → 異常終了
2. `/tmp/claude-story-xxx.log` でエラー原因を確認
3. INSTRUCTION.md を修正して tmux new-window で再起動（1回のみ）

### タイムアウト

- 対話モードのため `--max-budget-usd` は使用不可。PO が手動でタイムアウト判断する
- 30分経過しても通知が来ない場合、`tmux list-windows` でプロセス状態を確認
- 必要に応じて `tmux send-keys -t "story-xxx" C-c` で中断

## Resources

### references/

- **[architect-wave-planning.md](references/architect-wave-planning.md)**: Architect への Wave 計画策定依頼プロンプト
- **[wave-plan-template.md](references/wave-plan-template.md)**: Wave 計画書のフォーマット
- **[wave-prompts-template.md](references/wave-prompts-template.md)**: 各 Wave のサブエージェント起動プロンプト集
- **[instruction-template.md](references/instruction-template.md)**: Developer への INSTRUCTION.md フォーマット
- **[report-template.md](references/report-template.md)**: Developer の report.md フォーマット
