#!/bin/bash

# dotfiles セットアップスクリプト
# 使い方: ./setup.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "======================================"
echo "  dotfiles セットアップ"
echo "======================================"
echo ""
echo "dotfiles ディレクトリ: $DOTFILES_DIR"
echo ""

# バックアップディレクトリの作成
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# シンボリックリンクを作成する関数
create_symlink() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "  既存のファイルをバックアップ: $dest -> $BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    ln -s "$src" "$dest"
    echo "  ✓ リンク作成: $dest -> $src"
}

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

# Shell設定
if ask_yes_no "Shell設定 (.zshrc) をセットアップしますか？"; then
    create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
    [ -f "$DOTFILES_DIR/shell/.bash_profile" ] && create_symlink "$DOTFILES_DIR/shell/.bash_profile" "$HOME/.bash_profile"
fi

# Git設定
if ask_yes_no "Git設定 (.gitconfig) をセットアップしますか？"; then
    if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
        create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
    else
        echo "  ⚠ git/.gitconfig が見つかりません。git/.gitconfig.example を参考に作成してください。"
    fi
fi

# Vim設定
if ask_yes_no "Vim設定 (.vimrc) をセットアップしますか？"; then
    create_symlink "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

    if ask_yes_no "  vim-plugをインストールしますか？"; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        echo "  ✓ vim-plug インストール完了"
        echo "  ! Vimを開いて :PlugInstall を実行してください"
    fi
fi

# Neovim設定
if ask_yes_no "Neovim設定 (init.vim) をセットアップしますか？"; then
    mkdir -p "$HOME/.config/nvim"
    create_symlink "$DOTFILES_DIR/nvim/init.vim" "$HOME/.config/nvim/init.vim"
fi

# tmux設定
if ask_yes_no "tmux設定 (.tmux.conf) をセットアップしますか？"; then
    create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# VSCode設定
if ask_yes_no "VSCode設定 (settings.json) をセットアップしますか？"; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    if [ -d "$VSCODE_DIR" ]; then
        create_symlink "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/settings.json"
    else
        echo "  ⚠ VSCodeの設定ディレクトリが見つかりません: $VSCODE_DIR"
    fi
fi

# SSH設定
if ask_yes_no "SSH設定 (config) をセットアップしますか？"; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    create_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

# Claude Code設定
if ask_yes_no "Claude Code グローバル設定をセットアップしますか？"; then
    mkdir -p "$HOME/.claude"
    create_symlink "$DOTFILES_DIR/claude/global_CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    echo "  ! プロジェクトごとに /init コマンドで初期化してください"
fi

echo ""
echo "======================================"
echo "  セットアップ完了！"
echo "======================================"
echo ""
echo "バックアップは以下に保存されました:"
echo "  $BACKUP_DIR"
echo ""
echo "次のステップ:"
echo "  - シェル設定を反映: source ~/.zshrc"
echo "  - Vimプラグインをインストール: vim で :PlugInstall"
echo "  - tmuxを再起動: tmux kill-server && tmux"
echo ""
