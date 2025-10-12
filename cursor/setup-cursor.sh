#!/bin/bash

# Cursor 設定セットアップスクリプト
# 使い方: ./setup-cursor.sh [プロジェクトディレクトリ]

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# プロジェクトディレクトリの設定
if [ $# -eq 0 ]; then
    PROJECT_DIR="$(pwd)"
    echo "現在のディレクトリを使用: $PROJECT_DIR"
else
    PROJECT_DIR="$1"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "エラー: ディレクトリ '$PROJECT_DIR' が見つかりません"
        exit 1
    fi
fi

echo "======================================"
echo "  Cursor 設定セットアップ"
echo "======================================"
echo ""
echo "dotfiles ディレクトリ: $DOTFILES_DIR"
echo "プロジェクトディレクトリ: $PROJECT_DIR"
echo ""

# 確認プロンプト
ask_yes_no() {
    local prompt="$1"
    while true; do
        read -p "$prompt (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "y または n で答えてください。";;
        esac
    done
}

# ファイルをコピーする関数
copy_file() {
    local src="$1"
    local dest="$2"
    local description="$3"

    if [ ! -f "$src" ]; then
        echo "  ⚠ ソースファイルが見つかりません: $src"
        return 1
    fi

    # ディレクトリを作成
    mkdir -p "$(dirname "$dest")"

    # 既存ファイルのバックアップ
    if [ -f "$dest" ]; then
        if ask_yes_no "  既存のファイルをバックアップしますか？ ($dest)"; then
            cp "$dest" "$dest.backup.$(date +%Y%m%d_%H%M%S)"
            echo "  ✓ バックアップ作成: $dest"
        fi
    fi

    cp "$src" "$dest"
    echo "  ✓ $description: $dest"
}

# ディレクトリをコピーする関数
copy_directory() {
    local src="$1"
    local dest="$2"
    local description="$3"

    if [ ! -d "$src" ]; then
        echo "  ⚠ ソースディレクトリが見つかりません: $src"
        return 1
    fi

    # 既存ディレクトリのバックアップ
    if [ -d "$dest" ]; then
        if ask_yes_no "  既存のディレクトリをバックアップしますか？ ($dest)"; then
            mv "$dest" "$dest.backup.$(date +%Y%m%d_%H%M%S)"
            echo "  ✓ バックアップ作成: $dest"
        fi
    fi

    cp -r "$src" "$dest"
    echo "  ✓ $description: $dest"
}

# Cursor設定のコピー
if ask_yes_no "Cursor設定をコピーしますか？ (.cursor/, mcp.json)"; then
    # .cursor ディレクトリ全体をコピー
    mkdir -p "$PROJECT_DIR/.cursor"
    
    # rulesディレクトリをコピー
    if [ -d "$SCRIPT_DIR/rules" ]; then
        copy_directory "$SCRIPT_DIR/rules" "$PROJECT_DIR/.cursor/rules" "開発ガイドライン"
    fi
    
    # mcp.jsonをコピー
    if [ -f "$SCRIPT_DIR/mcp.json" ]; then
        copy_file "$SCRIPT_DIR/mcp.json" "$PROJECT_DIR/mcp.json" "MCP設定"
    fi
fi


echo ""
echo "======================================"
echo "  セットアップ完了！"
echo "======================================"
echo ""
echo "プロジェクト: $PROJECT_DIR"
echo ""
echo "作成されたファイル:"
if [ -d "$PROJECT_DIR/.cursor" ]; then
    find "$PROJECT_DIR/.cursor" -type f | sed 's/^/  /'
fi
if [ -f "$PROJECT_DIR/mcp.json" ]; then
    echo "  mcp.json"
fi
echo ""
echo "次のステップ:"
echo "  1. Cursor を再起動して設定を反映"
echo "  2. プロジェクト固有のルールを .cursor/rules/ に追加"
echo ""
echo "参考:"
echo "  - Cursor Rules: https://docs.cursor.com/ja/context/rules"
echo "  - 解説: https://zenn.dev/globis/articles/cursor-project-rules"
echo ""
