#!/bin/bash
# Maestro テストランナー
# Usage: maestro-test-runner.sh [make maestro-test の追加引数...]
# 出力: /tmp/maestro_output.txt に全出力を保存し、サマリーを stdout に出力

# プロジェクトルートを検出（pubspec.yaml がある場所まで遡る）
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/pubspec.yaml" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "$PWD"
  return 1
}

PROJECT_ROOT="$(find_project_root)"
TMP_DIR="$PROJECT_ROOT/.claude/tmp"
mkdir -p "$TMP_DIR"
LOG_FILE="$TMP_DIR/maestro_output.txt"

make maestro-test "$@" > "$LOG_FILE" 2>&1
EXIT_CODE=$?

echo "EXIT_CODE: $EXIT_CODE"
echo "--- Maestro Summary (last 30 lines) ---"
tail -n 30 "$LOG_FILE"

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "--- Failures ---"
  grep -E 'FAILED|══.*Exception|Expected:' "$LOG_FILE" | head -n 40
fi

exit $EXIT_CODE
