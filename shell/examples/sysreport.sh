#!/usr/bin/env bash
# =============================================================================
# sysreport.sh - システム情報レポートツール（教育用）
#
# 学べる概念:
#   変数, 関数, 条件分岐, ループ, 配列, コマンド置換,
#   ヒアドキュメント, トラップ, 引数処理, 終了コード, 色付き出力
# =============================================================================

# --- strict mode: エラーを早期検出する ---
set -euo pipefail

# --- 定数（readonly で再代入を防ぐ） ---
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly TMPFILE="$(mktemp)"

# --- トラップ: スクリプト終了時に一時ファイルを削除 ---
cleanup() {
  rm -f "$TMPFILE"
}
trap cleanup EXIT

# --- 色定義（ANSIエスケープコード） ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# --- ユーティリティ関数 ---

# 色付きでメッセージを表示する関数
print_color() {
  local color="$1"
  local message="$2"
  printf "${color}%s${RESET}\n" "$message"
}

# セクションヘッダーを表示する関数
print_header() {
  local title="$1"
  echo ""
  print_color "$BOLD$BLUE" "━━━ $title ━━━"
}

# コマンドの存在チェック
command_exists() {
  command -v "$1" &>/dev/null
}

# --- 使い方を表示（ヒアドキュメント） ---
usage() {
  cat <<EOF
使い方: $SCRIPT_NAME [オプション]

システム情報をレポートとして表示します。

オプション:
  -a, --all       全セクションを表示（デフォルト）
  -s, --summary   サマリーのみ表示
  -d, --disk      ディスク情報のみ表示
  -n, --network   ネットワーク情報のみ表示
  -o, --output    結果をファイルに出力
  -h, --help      この使い方を表示
  -v, --version   バージョンを表示

例:
  $SCRIPT_NAME --all
  $SCRIPT_NAME --disk --network
  $SCRIPT_NAME --output report.txt
EOF
}

# --- 各セクションの情報収集関数 ---

show_summary() {
  print_header "システムサマリー"

  local os_name kernel hostname uptime_str
  os_name="$(uname -s)"
  kernel="$(uname -r)"
  hostname="$(hostname)"
  uptime_str="$(uptime | sed 's/.*up /up /' | sed 's/,.*//')"

  # 連想配列的にラベルと値をペアで表示
  local -a labels=("ホスト名" "OS" "カーネル" "稼働時間" "シェル" "ユーザー")
  local -a values=("$hostname" "$os_name" "$kernel" "$uptime_str" "$SHELL" "$USER")

  # 配列をインデックスでループ
  for i in "${!labels[@]}"; do
    printf "  ${GREEN}%-12s${RESET}: %s\n" "${labels[$i]}" "${values[$i]}"
  done
}

show_cpu() {
  print_header "CPU情報"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    local cpu_name cores
    cpu_name="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo '不明')"
    cores="$(sysctl -n hw.ncpu 2>/dev/null || echo '不明')"
    printf "  %-12s: %s\n" "モデル" "$cpu_name"
    printf "  %-12s: %s\n" "コア数" "$cores"
  elif [[ -f /proc/cpuinfo ]]; then
    # Linuxの場合: grepとawkでパース
    local cpu_model core_count
    cpu_model="$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
    core_count="$(grep -c '^processor' /proc/cpuinfo)"
    printf "  %-12s: %s\n" "モデル" "$cpu_model"
    printf "  %-12s: %s\n" "コア数" "$core_count"
  else
    print_color "$YELLOW" "  CPU情報を取得できません"
  fi
}

show_disk() {
  print_header "ディスク使用量"

  # dfの出力をwhileループで1行ずつ処理
  df -h 2>/dev/null | head -1
  df -h 2>/dev/null | tail -n +2 | while IFS= read -r line; do
    local usage
    usage="$(echo "$line" | awk '{print $5}' | tr -d '%')"
    # 使用率に応じて色分け（条件分岐のネスト）
    if [[ "$usage" =~ ^[0-9]+$ ]]; then
      if (( usage >= 90 )); then
        printf "${RED}%s${RESET}\n" "$line"
      elif (( usage >= 70 )); then
        printf "${YELLOW}%s${RESET}\n" "$line"
      else
        echo "$line"
      fi
    else
      echo "$line"
    fi
  done
}

show_network() {
  print_header "ネットワーク情報"

  # 外部IPの取得（タイムアウト付き）
  if command_exists curl; then
    local external_ip
    external_ip="$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo '取得失敗')"
    printf "  %-16s: %s\n" "外部IP" "$external_ip"
  fi

  # ローカルIPの取得（OS判定で分岐）
  local local_ip
  case "$(uname -s)" in
    Darwin) local_ip="$(ipconfig getifaddr en0 2>/dev/null || echo 'N/A')" ;;
    Linux)  local_ip="$(hostname -I 2>/dev/null | awk '{print $1}')" ;;
    *)      local_ip="不明" ;;
  esac
  printf "  %-16s: %s\n" "ローカルIP" "$local_ip"
}

# --- メインロジック: 引数処理（getoptsの代わりにwhile+caseパターン） ---

main() {
  local show_all=true
  local -a sections=()
  local output_file=""

  # 引数がなければ全表示
  if [[ $# -eq 0 ]]; then
    sections=(summary cpu disk network)
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -a|--all)     sections=(summary cpu disk network) ;;
      -s|--summary) show_all=false; sections+=(summary) ;;
      -d|--disk)    show_all=false; sections+=(disk) ;;
      -n|--network) show_all=false; sections+=(network) ;;
      -o|--output)
        shift
        output_file="${1:?エラー: -o にはファイル名が必要です}"
        ;;
      -h|--help)    usage; exit 0 ;;
      -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
      *)
        print_color "$RED" "不明なオプション: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  # レポート生成
  print_color "$BOLD" "╔══════════════════════════════════╗"
  print_color "$BOLD" "║   システム情報レポート v$VERSION   ║"
  print_color "$BOLD" "╚══════════════════════════════════╝"
  printf "  生成日時: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"

  # セクション配列をforループで処理
  for section in "${sections[@]}"; do
    case "$section" in
      summary) show_summary ;;
      cpu)     show_cpu ;;
      disk)    show_disk ;;
      network) show_network ;;
    esac
  done

  echo ""
  print_color "$GREEN" "レポート完了"

  # ファイル出力（リダイレクトの活用）
  if [[ -n "$output_file" ]]; then
    # サブシェルで再実行し、色なしで出力
    RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET="" \
      main "${sections[@]/#/--}" > "$output_file" 2>&1 || true
    print_color "$GREEN" "ファイルに保存しました: $output_file"
  fi
}

# --- エントリポイント: スクリプトが直接実行された場合のみmainを呼ぶ ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
