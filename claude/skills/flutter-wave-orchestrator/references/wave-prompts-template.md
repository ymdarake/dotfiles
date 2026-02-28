# Wave サブエージェント起動プロンプト集

各 Wave で PO が使用するサブエージェント起動プロンプトのテンプレート。

## Wave 0: Architect 起動（共有 interface のみ）

```
Task tool → flutter-layer-first-architect:
"Wave 計画書に基づき、複数ストーリーにまたがる共有 interface の定義とスタブ実装を行ってください。

## Wave 計画書
doc/plan/WAVE_{YYYYMMDD}.md（※ {YYYYMMDD} は実際の日付に置換）

## 実施内容
計画書の「Wave 0: 共有アーキテクチャ準備」セクションの Tasks を全て実施してください。

## 注意事項
- 共有 interface（2つ以上のストーリーで使われるもの）の定義のみ行うこと
- ストーリー固有の interface や TODO マーカーは配置しないこと（Wave 1+ の Architect が担当）
- スタブは `throw UnimplementedError()` で実装
- 新しいパッケージ依存を追加した場合は `flutter pub get` を実行
- 既存テストを壊さないこと（`flutter test` で確認）"
```

## Wave 1+: Architect 起動（ストーリー固有 interface）

各 Wave の冒頭で、PO が Task tool で Architect を起動し、worktree 上にストーリー固有の
interface + スタブ + TODO マーカーを配置する。master 経由不要（feature ブランチに直接コミット）。

並列 Wave の場合、各 worktree に対して Architect を順次実行してから Developer を一斉起動する。

```
PO → Task tool → flutter-layer-first-architect:
"以下のストーリー固有 interface を worktree 上で実装してください。

プロジェクトルート: <worktree-path>

ストーリー: [STORY-XXX] <タイトル>
受け入れ条件: <Gherkin AC>

Wave 計画書の該当セクション:
<計画書から Architect Tasks を引用>

## 依頼事項
1. ストーリー固有の interface（abstract class）を定義
2. スタブ実装（NotImplementedError）
3. Developer が実装を開始できるよう TODO マーカーを配置
4. `dart analyze` がパスすることを確認
5. 変更を feature ブランチにコミット"
```

## Wave 1+: Developer 並列起動（tmux メッセージングモデル）

Task tool ではなく、tmux で独立した Claude インスタンスを起動する。
PO は以下の 3 ステップで各 Developer を起動する。

### Step 1: INSTRUCTION.md の作成

PO が各 worktree ルートに INSTRUCTION.md を Write で作成する。
フォーマット: [instruction-template.md](instruction-template.md)

PO の tmux ペイン ID は以下で取得:
```bash
tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
```

### Step 2: tmux new-window で Claude CLI 起動

各ストーリーごとに tmux で新ウィンドウを作成し、Developer を起動する。

```bash
tmux new-window -n "story-xxx" -c "../<project>-story-xxx" \
  "WAVE_PO_TMUX_TARGET='<po-pane>' WAVE_STORY_ID='STORY-XXX' \
  claude --agent flutter-developer \
    --permission-mode bypassPermissions \
    'INSTRUCTION.md を読んで指示に従って TDD サイクルで実装してください' \
    2>&1 | tee /tmp/claude-story-xxx.log; \
  touch /tmp/claude-story-xxx-exited"
```

### Step 3: 完了通知の受信と report.md の読み取り

Developer が実装完了すると tmux send-keys で PO に通知が届く。
PO は report.md を Read し、品質ゲート（YAML Frontmatter）を確認する。

フォールバック: `/tmp/claude-story-xxx-exited` で異常終了を検知。

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
doc/plan/WAVE_{YYYYMMDD}.md（※ {YYYYMMDD} は実際の日付に置換） を参照。

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
