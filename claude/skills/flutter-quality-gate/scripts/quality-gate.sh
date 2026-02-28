#!/bin/bash
# Flutter 品質ゲート: テスト + analyze + DDD依存チェック を一括実行
# Usage: quality-gate.sh [project_root]
#   project_root: Flutter プロジェクトルート（デフォルト: カレントディレクトリ）
#
# 終了コード:
#   0: 全チェック通過
#   1: いずれかのチェックで失敗

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" || { echo "ERROR: Cannot cd to $PROJECT_ROOT"; exit 1; }

TMP_DIR="$PROJECT_ROOT/.claude/tmp"
mkdir -p "$TMP_DIR"
LOG_FILE="$TMP_DIR/flutter_quality_gate.txt"
EXIT_CODE=0

echo "=== Flutter 品質ゲート ==="
echo "プロジェクト: $(pwd)"
echo ""

# --- 1. flutter test ---
echo "--- [1/3] flutter test ---"
flutter test > "$LOG_FILE" 2>&1
TEST_EXIT=$?
if [ $TEST_EXIT -eq 0 ]; then
  PASS_COUNT=$(grep -oE '\+[0-9]+' "$LOG_FILE" | tail -1 | tr -d '+')
  echo "✅ テスト全パス (${PASS_COUNT:-?} 件)"
else
  echo "❌ テスト失敗 (EXIT_CODE: $TEST_EXIT)"
  echo "--- 失敗箇所 ---"
  grep -A 5 -E 'FAILED|══.*Exception|Expected:' "$LOG_FILE" | head -n 40
  EXIT_CODE=1
fi
echo ""

# --- 2. flutter analyze ---
echo "--- [2/3] flutter analyze ---"
ANALYZE_OUTPUT=$(flutter analyze --no-fatal-infos 2>&1)
ANALYZE_EXIT=$?
if [ $ANALYZE_EXIT -eq 0 ]; then
  # info レベルの issue があれば表示（失敗にはしない）
  INFO_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -cE 'info •' || true)
  if [ "$INFO_COUNT" -gt 0 ]; then
    echo "✅ analyze エラーなし (info: ${INFO_COUNT} 件)"
  else
    echo "✅ analyze エラーなし"
  fi
else
  ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -cE '(error|warning) •')
  echo "❌ analyze で問題検出 (${ERROR_COUNT} 件)"
  echo "$ANALYZE_OUTPUT" | grep -E '(error|warning) •' | head -n 20
  EXIT_CODE=1
fi
echo ""

# --- 3. DDD 依存方向チェック ---
echo "--- [3/3] DDD 依存方向チェック ---"
DDD_SCRIPT="$PROJECT_ROOT/script/ddd-dependency-check.sh"
if [ -x "$DDD_SCRIPT" ]; then
  DDD_OUTPUT=$("$DDD_SCRIPT" "$PROJECT_ROOT" 2>&1)
  DDD_EXIT=$?
  if [ $DDD_EXIT -eq 0 ]; then
    echo "✅ 依存方向に問題なし"
  else
    echo "❌ 依存方向違反あり"
    echo "$DDD_OUTPUT" | grep -E '❌'
    EXIT_CODE=1
  fi
else
  echo "⏭️ スキップ: $DDD_SCRIPT が見つかりません"
fi

echo ""
echo "=== 結果 ==="
if [ $EXIT_CODE -eq 0 ]; then
  echo "🎉 品質ゲート通過"
else
  echo "⚠️ 品質ゲート失敗"
fi

exit $EXIT_CODE
