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
  → 各 doc/plan/STORY-XXX.md を生成

Phase 2: Wave 計画策定（flutter-layer-first-architect）
  → 全 Plan を読み、競合分析 + 共有 interface 特定 + Wave 分割
  → doc/plan/WAVE_{YYYYMMDD}.md に出力

Phase 3: Wave 実行（PO がオーケストレーション）
  → Wave 0: flutter-layer-first-architect が「複数ストーリーにまたがる共有 interface」のみ実装
  → Wave 1+: 各 Wave 冒頭で Architect がストーリー固有 interface を worktree 上に実装
              → Developer が TDD 実装（並列時: tmux + worktree、直列時: Task tool）
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

PO が各出力を `doc/plan/STORY-XXX.md` に Write で保存する。

---

## Phase 2: Wave 計画策定（flutter-layer-first-architect）

全ストーリーの Plan が揃ったら、`flutter-layer-first-architect` に Wave 計画策定を委譲する。

`flutter-layer-first-architect` への依頼プロンプトは [architect-wave-planning.md](references/architect-wave-planning.md) を参照。

`flutter-layer-first-architect` の出力を PO が `doc/plan/WAVE_{YYYYMMDD}.md` に保存する。
計画書のフォーマットは [wave-plan-template.md](references/wave-plan-template.md) に従う。

### 計画書の確認ポイント

PO は以下を確認してから Phase 3 に進む:
- [ ] 全対象ストーリーが Wave に割り当てられているか
- [ ] 順序制約の理由が明確か
- [ ] Wave 0 の共有 interface + 各 Wave の固有 interface が全ストーリーの AC をカバーしているか
- [ ] Git worktree 戦略が定義されているか

---

## Phase 3: Wave 実行

計画書に従い、PO が各 Wave を順次実行する。
各 Wave のサブエージェント起動プロンプトは [wave-prompts-template.md](references/wave-prompts-template.md) を参照。

### 並列実行の判断基準

**tmux を使うのは、同一 Wave 内で2つ以上のストーリーを並列実行する場合のみ。**

並列実行しないケース（以下のいずれか）では、tmux・worktree・bypassPermissions を使わず、
通常の Task tool サブエージェント（`flutter-developer`）でメインリポジトリ上で直接実装する:

- Wave 内のストーリーが1つだけ
- ストーリー間に順序依存があり、結果的に直列実行になる
- 計画書で並列不要と判断されている

**理由:** tmux + `bypassPermissions` はガードレール（`wave-guardrail.sh`）で保護されるが、
並列の必要がなければそのリスクを取る理由がない。通常の permission-mode で対話的に実行する方が安全。

### ⚠️ 絶対ルール: worktree の直接編集禁止

**PO（オーケストレーター）やそのサブエージェント（Task tool 経由）から、worktree 内のファイルを直接編集してはならない。**

worktree はプロジェクト外ディレクトリ（`../<project>-story-xxx/`）のため、Task tool サブエージェントの
パーミッションパターンが効かず、すべてのファイル操作で許可プロンプトが発生する。

worktree でのファイル操作は、**必ず tmux で独立した Claude プロセスを起動し、worktree を cwd にすること。**
これは Architect（Step 1.5）にも Developer（Step 3）にも適用される。

### Wave 0: 共有アーキテクチャ準備

`flutter-layer-first-architect` が **2つ以上のストーリーで使われる共有 interface** のみを master に実装する。
ストーリー固有の interface は Wave 1+ で各 worktree に直接実装するため、ここでは対象外。

**共有 interface の定義基準:**
- 2つ以上のストーリーの AC 実現に必要な Repository / Service / Entity
- 計画書の「共有 Interface」セクションに記載されたもの

**品質ゲート（Wave 0 → Wave 1 の条件）:**
- [ ] `dart analyze` パス
- [ ] `flutter test` パス（既存テストの回帰なし）
- [ ] 共有 interface が定義済み + スタブ実装（NotImplementedError）
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
# ガードレール用 settings.json を上書き
cp .claude/skills/flutter-wave-orchestrator/references/worktree-settings.json \
  ../<project>-story-xxx/.claude/settings.json
# wave-guardrail.sh は cp -r .claude で既にコピー済み
(cd ../<project>-story-xxx && flutter pub get)
# ※ サブシェルで実行するためカレントディレクトリは変わらない
# ※ .claude/ を必ずコピーする（worktree には自動コピーされない）
# ※ クリーンアップはここではやらない。Wave N-1 のマージ完了後に行う
```

#### Step 1.5: Architect によるストーリー固有 interface 定義

PO が tmux で `flutter-layer-first-architect` を起動し、worktree 上でストーリー固有の
interface + スタブ + TODO マーカーを配置する。**master 経由不要**（feature ブランチに直接コミット）。

- **実行方法**: tmux + bypassPermissions（worktree は外部ディレクトリのため Task tool では許可プロンプトが全操作で発生する）
- **実行場所**: 各 worktree ディレクトリ
- **並列 Wave の場合**: 各 worktree に対して Architect を並列起動し、全完了後に Developer を一斉起動する

**⚠️ Task tool で worktree を直接編集してはならない。** worktree はプロジェクト外ディレクトリのため、
すべてのファイル操作で許可プロンプトが発生する。必ず tmux でプロセスを分離すること。

```bash
# PO: Architect を worktree 上で起動
tmux new-window -n "arch-story-xxx" -c "../<project>-story-xxx" \
  "claude --agent flutter-layer-first-architect \
    --permission-mode bypassPermissions \
    -p '以下のストーリー固有 interface を実装してください。

ストーリー: [STORY-XXX] <タイトル>
受け入れ条件: <Gherkin AC>

Wave 計画書の該当セクション:
<計画書から Architect Tasks を引用>

## 依頼事項
1. ストーリー固有の interface（abstract class）を定義
2. スタブ実装（NotImplementedError）
3. Developer が実装を開始できるよう TODO マーカーを配置
4. dart analyze がパスすることを確認
5. 変更を feature ブランチにコミット' \
    2>&1 | tee /tmp/claude-arch-story-xxx.log; \
  echo \$? > /tmp/claude-arch-story-xxx.exit_code"
```

**完了検知**: PO は `/tmp/claude-arch-story-xxx.exit_code` の出現を監視する。
`-p` ワンショットモードのため、Architect は処理完了後に自動終了する。

```bash
# PO: Architect 完了を待機（ポーリング）
while [ ! -f /tmp/claude-arch-story-xxx.exit_code ]; do sleep 5; done
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
  "WAVE_PO_TMUX_TARGET='<po-pane>' WAVE_STORY_ID='STORY-XXX' \
  claude --agent flutter-developer \
    --permission-mode bypassPermissions \
    'INSTRUCTION.md を読んで指示に従って TDD サイクルで実装してください' \
    2>&1 | tee /tmp/claude-story-xxx.log; \
  touch /tmp/claude-story-xxx-exited"
```

| 環境変数 | 値 | 用途 |
|---------|-----|------|
| `WAVE_PO_TMUX_TARGET` | PO の tmux pane ID | ガードレールのエスカレーション通知先 |
| `WAVE_STORY_ID` | ストーリー ID | エスカレーションファイルの識別子 |

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

## ガードレール（bypassPermissions 安全装置）

`--permission-mode bypassPermissions` で起動される Developer エージェントに対する安全装置。
PreToolUse hook（`wave-guardrail.sh`）が Bash/Write/Edit の呼び出し時に自動判定する。

### 2層構造

```
Developer が Bash/Write/Edit を呼び出す
  │
  ├─ PreToolUse hook (wave-guardrail.sh) が起動
  │
  ├─ Layer 1: HARD DENY（即座にブロック）
  │   └─ 絶対に許可しない操作 → 即 deny
  │
  ├─ Layer 2: PO エスカレーション（tmux 経由で承認待ち）
  │   └─ 文脈次第で正当な操作 → PO に判断を委ねる
  │
  └─ Layer 3: AUTO ALLOW
      └─ 通常の開発コマンド → 許可
```

### Layer 1: HARD DENY

| カテゴリ | パターン | 理由 |
|---------|---------|------|
| git push | `git push`（全種類） | push は PO の責務 |
| 破壊的 git | `git reset --hard`, `git clean -f`, `git checkout .`, `git branch -D` | worktree 状態の破壊 |
| システム破壊 | `sudo`, `chmod 777`, `eval` | セキュリティリスク |
| リモートスクリプト実行 | `curl\|bash`, `curl\|sh`, `wget\|python` 等 | リモートコード実行 |
| ワークスペース外書き出し | `curl -o /etc/...`, `wget -O /tmp/...`, `> /usr/...` | ファイルシステム汚染 |
| ルート削除 | `rm -rf /`, `rm -rf /*` | 致命的 |
| 自己改変 | `.claude/` 配下への Write/Edit | ガードレール自体の無効化を防止 |

### Layer 2: PO エスカレーション

| カテゴリ | パターン | 正当なケースの例 |
|---------|---------|----------------|
| 外部通信 | `curl`, `wget`, `ssh`, `scp`, `sftp`, `rsync`, `nc`, `telnet`, `ftp` | API 確認等（基本的に TDD 実装中は不要） |
| スクリプト実行 | `bash <file>`, `bash -c "..."`, `sh <file>`, `python <file>`, `./<file>`, `source <file>` | テストヘルパースクリプト等 |
| ディレクトリ削除 | `rm -r` / `rm -rf`（ルート以外） | build/ や .dart_tool/ のクリーン |
| git worktree | `git worktree` 操作 | PO から指示された場合 |
| worktree 外ファイル | 絶対パスが worktree 外を指す Write/Edit | 共有設定の更新（稀） |

**エスカレーションフロー:**
1. `/tmp/wave-escalation-{story}-{hash}.json` にリクエスト詳細を書き出し
2. `tmux send-keys` で PO に承認リクエストを送信
3. `/tmp/wave-response-{story}-{hash}` をポーリング（2秒間隔、120秒 timeout）
4. `approve` → 許可 / `deny` → 拒否 / timeout → 拒否（フェイルセーフ）

**環境変数（tmux 起動時に設定）:**
- `WAVE_PO_TMUX_TARGET`: PO の tmux pane ID（必須）
- `WAVE_STORY_ID`: ストーリー ID
- `WAVE_ESCALATION_TIMEOUT`: タイムアウト秒数（デフォルト: 120）

**実装ファイル:**
- hook 本体: `claude/hooks/wave-guardrail.sh`
- worktree 用 settings: `claude/skills/flutter-wave-orchestrator/references/worktree-settings.json`

---

## エラーハンドリング

### `flutter-developer` が設計不備を検知した場合

Wave 1+ の実装中に「interface が不足」と判明した場合:

**A. ストーリー固有の interface が不足している場合:**
1. `flutter-developer` が不足内容を報告して停止
2. PO が `flutter-layer-first-architect` を **該当 worktree 上で** Task tool で再起動
3. Architect が不足 interface を worktree に追加（feature ブランチに直接コミット）
4. `flutter-developer` を再開

**B. 複数ストーリーにまたがる共有 interface が不足している場合:**
1. `flutter-developer` が不足内容を報告して停止
2. PO が `flutter-layer-first-architect` を **master 上で** 再起動し、共有 interface を追加
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
- **[worktree-settings.json](references/worktree-settings.json)**: worktree 用 `.claude/settings.json` テンプレート（ガードレール hook 登録済み）
