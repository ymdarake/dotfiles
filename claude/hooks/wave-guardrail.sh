#!/bin/bash
# wave-guardrail.sh - bypassPermissions 用 PreToolUse ガードレール
#
# flutter-wave-orchestrator の tmux メッセージングモデルで、
# --permission-mode bypassPermissions で起動された Developer エージェントに
# 対する安全装置。PreToolUse hook として登録して使用する。
#
# 2層構造:
#   Layer 1: 静的ルールで即 deny（HARD DENY）
#   Layer 2: PO に tmux 経由でエスカレーション（承認待ち）
#   Layer 3: 上記以外は auto allow
#
# 環境変数:
#   WAVE_PO_TMUX_TARGET: PO の tmux pane ID（Layer 2 で必須）
#   WAVE_STORY_ID: ストーリー ID（Layer 2 のリクエストファイル名に使用）
#   WAVE_ESCALATION_TIMEOUT: エスカレーション待ち時間（デフォルト: 120秒）
#
# 依存:
#   jq（なければフェイルオープン: exit 0）

# --- jq 依存チェック ---
if ! command -v jq &>/dev/null; then
  exit 0
fi

# --- 入力パース ---
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode // empty')

# bypassPermissions 以外ではスキップ
if [ "$PERMISSION_MODE" != "bypassPermissions" ]; then
  exit 0
fi

# ツール別の入力値を取得
COMMAND=""
FILE_PATH=""
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
elif [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
fi

# deny を出力して終了するヘルパー
deny() {
  local reason="$1"
  cat <<EOF
{"decision": "deny", "reason": "$reason"}
EOF
  exit 0
}

# ============================================================
# Layer 1: HARD DENY（即座にブロック、PO 問い合わせ不要）
# ============================================================

if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  # --- git push（全種類） ---
  if echo "$COMMAND" | grep -qE 'git\s+push'; then
    deny "HARD DENY: git push は PO の責務です"
  fi

  # --- 破壊的 git 操作 ---
  if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    deny "HARD DENY: git reset --hard は worktree 状態を破壊します"
  fi
  if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
    deny "HARD DENY: git clean -f は worktree 状態を破壊します"
  fi
  if echo "$COMMAND" | grep -qE 'git\s+checkout\s+\.'; then
    deny "HARD DENY: git checkout . は worktree 状態を破壊します"
  fi
  if echo "$COMMAND" | grep -qE 'git\s+restore\s+\.'; then
    deny "HARD DENY: git restore . は worktree 状態を破壊します"
  fi
  if echo "$COMMAND" | grep -qE 'git\s+branch\s+-D'; then
    deny "HARD DENY: git branch -D はブランチを強制削除します"
  fi

  # --- システム破壊 ---
  if echo "$COMMAND" | grep -qE 'sudo\s'; then
    deny "HARD DENY: sudo は許可されていません"
  fi
  if echo "$COMMAND" | grep -qE 'chmod\s+777'; then
    deny "HARD DENY: chmod 777 は許可されていません"
  fi
  if echo "$COMMAND" | grep -qE 'curl\s.*\|\s*(bash|sh|zsh|python3?|ruby|perl|node)'; then
    deny "HARD DENY: curl でリモートスクリプトをパイプ実行することは許可されていません"
  fi
  if echo "$COMMAND" | grep -qE 'wget\s.*\|\s*(bash|sh|zsh|python3?|ruby|perl|node)'; then
    deny "HARD DENY: wget でリモートスクリプトをパイプ実行することは許可されていません"
  fi
  if echo "$COMMAND" | grep -qE 'eval\s'; then
    deny "HARD DENY: eval は許可されていません"
  fi

  # --- ルート削除 ---
  if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+/\s*$'; then
    deny "HARD DENY: rm -rf / は許可されていません"
  fi
  if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+/\*'; then
    deny "HARD DENY: rm -rf /* は許可されていません"
  fi

  # --- curl/wget によるワークスペース外へのファイル書き出し ---
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  if [ -n "$CWD" ]; then
    output_path=""
    if echo "$COMMAND" | grep -qE 'curl\s'; then
      output_path=$(echo "$COMMAND" | grep -oE '(-o|--output) +[^ ]+' | head -1 | sed 's/^-o *//;s/^--output *//')
    fi
    if echo "$COMMAND" | grep -qE 'wget\s'; then
      output_path=$(echo "$COMMAND" | grep -oE '(-O|--output-document[= ]) *[^ ]+' | head -1 | sed 's/^-O *//;s/^--output-document[= ] *//')
    fi
    if [ -z "$output_path" ]; then
      output_path=$(echo "$COMMAND" | grep -oE '> *[^ ]+' | head -1 | sed 's/^> *//')
    fi
    if [ -n "$output_path" ]; then
      case "$output_path" in
        /*) abs_path="$output_path" ;;
        *)  abs_path="$CWD/$output_path" ;;
      esac
      case "$abs_path" in
        "$CWD"/*) ;;
        *) deny "HARD DENY: ワークスペース外へのファイル書き出しは許可されていません ($abs_path)" ;;
      esac
    fi
  fi
fi

# --- .claude/ 配下への Write/Edit（自己改変防止） ---
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -qE '(^|/)\.claude/'; then
    deny "HARD DENY: .claude/ 配下の変更は許可されていません（ガードレール保護）"
  fi
fi

# ============================================================
# Layer 2: PO エスカレーション（文脈次第で正当な場合がある操作）
# ============================================================

needs_escalation=false
escalation_reason=""

if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  # --- スクリプト実行の検出 ---
  # 既知の安全なコマンドは除外
  is_safe_command=false
  if echo "$COMMAND" | grep -qE '^\s*(flutter|dart|git|npm|npx|pub|brew|which|echo|cat|ls|mkdir|cp|mv|touch|head|tail|wc|sort|uniq|diff|find|grep|sed|awk|tr|cut|tee|xargs)\s'; then
    is_safe_command=true
  fi

  if [ "$is_safe_command" = false ]; then
    # bash <file>, bash -c "...", sh <file>, python <file>, ./<file>, source <file>
    if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)(bash|sh|zsh)\s+\S'; then
      needs_escalation=true
      escalation_reason="bash/sh によるコマンド実行"
    fi
    if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)(python3?|ruby|perl|node)\s'; then
      needs_escalation=true
      escalation_reason="スクリプトの実行"
    fi
    if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)(\./)'; then
      needs_escalation=true
      escalation_reason="実行可能ファイルの直接実行"
    fi
    if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)source\s'; then
      needs_escalation=true
      escalation_reason="source によるスクリプト実行"
    fi
  fi

  # --- ディレクトリ削除（ルート以外） ---
  if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r'; then
    # Layer 1 でルート削除は deny 済み。ここに来るのはルート以外
    needs_escalation=true
    escalation_reason="ディレクトリの再帰的削除"
  fi

  # --- git worktree 操作 ---
  if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)git\s+worktree(\s|$)'; then
    needs_escalation=true
    escalation_reason="git worktree 操作"
  fi

  # --- 外部通信コマンド ---
  # TDD 実装中に外部通信は基本不要（pub get は PO が Step 1 で実施済み）
  # curl/wget のワークスペース外書き出し・パイプ実行は Layer 1 で HARD DENY 済み
  # ここでは残りの全外部通信をエスカレーション対象にする
  if echo "$COMMAND" | grep -qE '(curl|wget|ssh|scp|sftp|rsync|nc|netcat|ncat|telnet|ftp)\s'; then
    needs_escalation=true
    escalation_reason="外部通信コマンドの実行"
  fi
fi

# --- worktree 外ファイルへの Write/Edit ---
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  if [ -n "$FILE_PATH" ]; then
    # 絶対パスかつ cwd の外を指す場合
    CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
    if [ -n "$CWD" ] && [ -n "$FILE_PATH" ]; then
      # FILE_PATH が CWD 配下でなければエスカレーション
      case "$FILE_PATH" in
        "$CWD"/*)
          # CWD 配下 → OK
          ;;
        *)
          # CWD 外のファイル
          needs_escalation=true
          escalation_reason="worktree 外のファイルへの書き込み ($FILE_PATH)"
          ;;
      esac
    fi
  fi
fi

# --- エスカレーション処理 ---
if [ "$needs_escalation" = true ]; then
  PO_TARGET="${WAVE_PO_TMUX_TARGET:-}"
  STORY_ID="${WAVE_STORY_ID:-UNKNOWN}"
  TIMEOUT="${WAVE_ESCALATION_TIMEOUT:-120}"

  # PO 環境変数がなければ deny にフォールバック
  if [ -z "$PO_TARGET" ]; then
    deny "ESCALATE (フォールバック deny): $escalation_reason - WAVE_PO_TMUX_TARGET 未設定のため自動 deny"
  fi

  # リクエスト ID 生成
  REQ_HASH=$(echo "$TOOL_NAME:$COMMAND$FILE_PATH:$$:$(date +%s)" | shasum | cut -c1-8)
  ESCALATION_FILE="/tmp/wave-escalation-${STORY_ID}-${REQ_HASH}.json"
  RESPONSE_FILE="/tmp/wave-response-${STORY_ID}-${REQ_HASH}"

  # エスカレーションリクエストファイル作成
  cat > "$ESCALATION_FILE" <<REQEOF
{
  "story_id": "$STORY_ID",
  "tool_name": "$TOOL_NAME",
  "command": $(echo "$COMMAND$FILE_PATH" | jq -Rs .),
  "reason": "$escalation_reason",
  "response_file": "$RESPONSE_FILE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
REQEOF

  # PO に tmux 経由で通知
  DISPLAY_CMD="$COMMAND$FILE_PATH"
  # 改行をスペースに置換（コマンドインジェクション防止）
  DISPLAY_CMD=$(echo "$DISPLAY_CMD" | tr '\n' ' ')
  # 長すぎるコマンドは省略
  if [ ${#DISPLAY_CMD} -gt 80 ]; then
    DISPLAY_CMD="${DISPLAY_CMD:0:77}..."
  fi

  tmux send-keys -t "$PO_TARGET" C-c 2>/dev/null
  sleep 0.2
  tmux send-keys -t "$PO_TARGET" -l \
    "[${STORY_ID}] 要承認: ${escalation_reason} - ${DISPLAY_CMD} | Read ${ESCALATION_FILE} で詳細確認。echo approve/deny > ${RESPONSE_FILE}" 2>/dev/null
  tmux send-keys -t "$PO_TARGET" Enter 2>/dev/null

  # レスポンスをポーリング（2秒間隔）
  elapsed=0
  while [ "$elapsed" -lt "$TIMEOUT" ]; do
    if [ -f "$RESPONSE_FILE" ]; then
      response=$(cat "$RESPONSE_FILE")
      # クリーンアップ
      rm -f "$ESCALATION_FILE" "$RESPONSE_FILE"

      if echo "$response" | grep -qi "approve"; then
        exit 0
      else
        deny "PO により deny されました: $escalation_reason"
      fi
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  # タイムアウト → deny（フェイルセーフ）
  rm -f "$ESCALATION_FILE" "$RESPONSE_FILE"
  deny "エスカレーション タイムアウト (${TIMEOUT}秒): $escalation_reason"
fi

# ============================================================
# Layer 3: AUTO ALLOW
# ============================================================
exit 0
