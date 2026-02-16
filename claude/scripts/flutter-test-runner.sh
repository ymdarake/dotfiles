#!/bin/bash
# Flutter テストランナー
# Usage: flutter-test-runner.sh [flutter test の引数...]
# 出力: /tmp/test_output.txt に全出力を保存し、サマリーを stdout に出力

LOG_FILE="/tmp/test_output.txt"

flutter test "$@" > "$LOG_FILE" 2>&1
EXIT_CODE=$?

echo "EXIT_CODE: $EXIT_CODE"
echo "--- Test Summary (last 20 lines) ---"
tail -n 20 "$LOG_FILE"

if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "--- Failures ---"
  grep -A 5 -E 'FAILED|══.*Exception|Expected:' "$LOG_FILE" | head -n 60
fi

exit $EXIT_CODE
