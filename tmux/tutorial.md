# tmux チュートリアル

自分の `.tmux.conf` に合わせた操作リファレンス。
Wave 開発（Claude Code の並列実行）で使う操作を中心にまとめている。

## 前提: 3層構造

```
Session (プロジェクト単位 = ブラウザのウィンドウ)
  └─ Window (作業コンテキスト = ブラウザのタブ)
       └─ Pane (画面分割 = 1タブ内の分割ビュー)
```

## 注意事項

- Cursor の統合ターミナルでは `C-q` が競合する。Terminal.app / iTerm2 で使うこと
- `base-index: 1` なのでウィンドウ・ペイン番号は 1 から始まる

## キーバインド一覧（Prefix: C-q）

### ペイン操作

| 操作 | キー | 説明 |
|------|------|------|
| 縦分割 | `C-q \|` | 左右に分割 |
| 横分割 | `C-q -` | 上下に分割 |
| ペイン移動 | `C-q h/j/k/l` | vim 風に移動 |
| ペイン閉じ | `C-q x` | 確認なしで即閉じ |
| ズーム | `C-q z` | 全画面化 / 戻す |
| リサイズ | マウスドラッグ | 境界線をドラッグ |

### ウィンドウ操作

| 操作 | キー | 説明 |
|------|------|------|
| 新規作成 | `C-q c` | 新しいウィンドウ（タブ）を作成 |
| 名前変更 | `C-q ,` | 現在のウィンドウ名を変更 |
| 番号で移動 | `C-q 1` / `C-q 2` | ウィンドウ番号で直接移動 |
| 次 / 前 | `C-q n` / `C-q p` | 順に切り替え |
| 一覧表示 | `C-q w` | ツリービューで選択 |

### コピー

| 操作 | キー | 説明 |
|------|------|------|
| コピーモード | `C-q [` | スクロール・選択モードに入る |
| 選択開始 | `Space` | コピーモード内 |
| 選択確定 | `Enter` | tmux バッファにコピー |
| ペースト | `C-q ]` | tmux バッファから貼り付け |
| macOS コピー | `Option + ドラッグ → Cmd+C` | macOS クリップボードに直接コピー |

### その他

| 操作 | キー | 説明 |
|------|------|------|
| 設定リロード | `C-q r` | `.tmux.conf` を再読み込み |

## CLI コマンド（Wave 開発で使う）

### 状態確認

```bash
# 全ウィンドウの一覧
tmux list-windows

# 全ペインの一覧
tmux list-panes

# 自分のペイン ID を取得（INSTRUCTION.md の po_tmux_target に使う）
tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
```

### ウィンドウ作成・削除

```bash
# 名前付きウィンドウを作成してコマンドを実行
tmux new-window -n "story-xxx" -c "/path/to/worktree" "command"

# ウィンドウを閉じる
tmux kill-window -t <window-name>

# ウィンドウを切り替える
tmux select-window -t <window-name>
```

### send-keys（ウィンドウ間メッセージ送信）

```bash
# ターゲットにコマンドを送信
tmux send-keys -t <target> "command" Enter

# リテラル送信（特殊文字を解釈させない）
tmux send-keys -t <target> -l 'literal text'

# Wave の Developer → PO 通知パターン
tmux send-keys -t <po-pane> C-c                                          # 行クリア
tmux send-keys -t <po-pane> -l '[STORY-XXX] 完了。Read /path/report.md'  # 通知本文
tmux send-keys -t <po-pane> Enter                                        # 送信
```

### ペインの内容をキャプチャ

```bash
# ペインの表示内容を取得（デバッグ用）
tmux capture-pane -t <target> -p
```

## Wave 開発での使い方

```
PO（tmux ウィンドウ 1: po）
  │
  ├─ tmux display-message で自分のペイン ID を取得
  ├─ 各 worktree に INSTRUCTION.md を配置（po_tmux_target を記載）
  │
  ├─ tmux new-window -n "story-017" -c "../project-story-017" "claude ..."
  ├─ tmux new-window -n "story-018" -c "../project-story-018" "claude ..."
  │
  ├─ Developer A: 実装完了 → tmux send-keys で PO に通知
  ├─ Developer B: 実装完了 → tmux send-keys で PO に通知
  │
  └─ PO: 通知受信 → report.md を Read → 品質ゲート判定
```

ステータスバーのイメージ:
```
[wave] 1:po* 2:story-017 3:story-018
```
