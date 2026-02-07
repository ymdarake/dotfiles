#!/bin/bash
# check-diff-size.sh
# Stop hookで実行され、差分が閾値を超えた場合にGeminiコードレビューを指示する
#
# 仕組み:
#   - git diff --numstat で変更行数（追加+削除）を計算
#   - 閾値（デフォルト100行）超過時に block 判定を出力
#   - 一時マーカーファイルで無限ループを防止（一度blockしたら15分間は再発動しない）
#
# 環境変数:
#   GEMINI_REVIEW_DIFF_THRESHOLD: 差分の閾値（デフォルト: 100）
#   GEMINI_REVIEW_COOLDOWN_MINUTES: クールダウン時間（デフォルト: 15分）

# --- 無限ループ防止: マーカーファイル方式 ---
# リポジトリごとに一意のマーカーファイルを生成
repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
  exit 0
fi
repo_hash=$(echo "$repo_root" | shasum | cut -d' ' -f1)
MARKER_FILE="/tmp/gemini-review-blocked-${repo_hash}"
COOLDOWN_MINUTES="${GEMINI_REVIEW_COOLDOWN_MINUTES:-5}"

# マーカーファイルが存在し、クールダウン期間内ならスキップ
if [ -f "$MARKER_FILE" ]; then
  # find -mmin +N: N分より古ければ出力される → 古ければexpire
  if [ -z "$(find "$MARKER_FILE" -mmin +"$COOLDOWN_MINUTES" 2>/dev/null)" ]; then
    # まだクールダウン中 → スキップ
    exit 0
  else
    # 期限切れ → マーカー削除して再チェック
    rm -f "$MARKER_FILE"
  fi
fi

# 閾値の設定（デフォルト: 100行）
THRESHOLD="${GEMINI_REVIEW_DIFF_THRESHOLD:-100}"

# 整数チェック（不正な値ならデフォルトの100にリセット）
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  THRESHOLD=100
fi

# git diff --numstat で変更行数を計算（staged + unstaged）
# 出力形式: 追加行数\t削除行数\tファイル名
total_lines=0

# ロックファイル・自動生成ファイルの除外パターン
LOCK_PATTERN='(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|go\.sum|Cargo\.lock)$'

while IFS=$'\t' read -r added deleted _file; do
  # バイナリファイルは "-" になるのでスキップ
  if [ "$added" = "-" ] || [ "$deleted" = "-" ]; then
    continue
  fi
  if [[ "$_file" =~ $LOCK_PATTERN ]]; then
    continue
  fi
  total_lines=$((total_lines + added + deleted))
done < <(git diff --numstat 2>/dev/null; git diff --cached --numstat 2>/dev/null)

# untracked ファイルの行数もカウント（新規作成ファイルの検出）
while IFS= read -r ufile; do
  # ロックファイル・自動生成ファイルを除外
  if [[ "$ufile" =~ $LOCK_PATTERN ]]; then
    continue
  fi
  # バイナリファイルをスキップ（file コマンドで判定）
  if file --brief --mime "$ufile" 2>/dev/null | grep -qv 'text/'; then
    continue
  fi
  lines=$(wc -l < "$ufile" 2>/dev/null || echo 0)
  total_lines=$((total_lines + lines))
done < <(git ls-files --others --exclude-standard 2>/dev/null)

# 閾値未満なら何もしない
if [ "$total_lines" -lt "$THRESHOLD" ]; then
  exit 0
fi

# マーカーファイルを作成（クールダウン開始）
touch "$MARKER_FILE"

# 閾値超過: block 判定を出力し、Geminiコードレビューを指示
cat <<EOF
{"decision": "block", "reason": "差分が${total_lines}行（閾値: ${THRESHOLD}行）を超えています。gemini-code-review スキルでGeminiコードレビューを実行してください。レビュー完了後に作業を終了してください。"}
EOF
