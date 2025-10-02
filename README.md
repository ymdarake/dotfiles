# dotfiles

個人の開発環境設定を管理するリポジトリです。

## 📁 ディレクトリ構成

- [`shell/`](./shell) - シェル設定（.zshrc, .bash_profile等）
- [`git/`](./git) - Git設定（.gitconfig）
- [`vim/`](./vim) - Vim設定（.vimrc）
- [`nvim/`](./nvim) - Neovim設定（init.vim）
- [`tmux/`](./tmux) - tmux設定（.tmux.conf）
- [`vscode/`](./vscode) - VSCode設定（settings.json）
- [`ssh/`](./ssh) - SSH設定（config）
- [`claude/`](./claude) - Claude Code設定サンプル

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/ymdarake/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. セットアップ

#### 自動セットアップ（推奨）

```bash
./setup.sh
```

#### 手動セットアップ

各ディレクトリのREADME.mdを参照して、必要な設定をシンボリックリンクで適用：

```bash
# 例: zsh設定
ln -s ~/dotfiles/shell/.zshrc ~/.zshrc

# 例: git設定
ln -s ~/dotfiles/git/.gitconfig ~/.gitconfig

# 例: Claude Code グローバル設定
mkdir -p ~/.claude
ln -s ~/dotfiles/claude/global_CLAUDE.md ~/.claude/CLAUDE.md
```

## 📝 各設定の詳細

各ディレクトリに詳細なREADME.mdがあります：

- [Shell](./shell/README.md) - zshの設定とエイリアス
- [Git](./git/README.md) - Gitのエイリアスと設定
- [Vim](./vim/README.md) - Vimプラグインと設定
- [Neovim](./nvim/README.md) - Neovim設定
- [tmux](./tmux/README.md) - tmuxキーバインドと設定
- [VSCode](./vscode/README.md) - VSCode拡張機能と設定
- [SSH](./ssh/README.md) - SSH接続設定
- [Claude Code](./claude/README.md) - Claude Code設定ガイド

## 🔧 カスタマイズ

### 機密情報の扱い

機密情報（SSH秘密鍵、トークン等）は `.gitignore` で除外されています。
個人情報を含む設定は `.example` ファイルを参考に作成してください。

### 新しい設定の追加

1. 専用ディレクトリを作成
2. README.md で説明を記載
3. サンプルファイルを用意
4. シンボリックリンクコマンドを明記

## 💡 便利なコマンド

```bash
# dotfilesリポジトリの更新を取得
cd ~/dotfiles && git pull

# 設定の再読み込み（zsh）
source ~/.zshrc

# tmuxセッション開始
tmux
```

## 📚 参考リンク

- [GitHub Dotfiles Guide](https://dotfiles.github.io/)
- [Claude Code Documentation](https://docs.claude.com/claude-code)

## ライセンス

MIT License
