# Neovim 設定

Neovimの設定ファイルです。

## 📄 ファイル

- `init.vim` - Neovim設定ファイル

## 🚀 セットアップ

### 1. Neovimのインストール

```bash
brew install neovim
```

### 2. 設定ディレクトリの作成

```bash
mkdir -p ~/.config/nvim
```

### 3. init.vim のシンボリックリンク作成

```bash
ln -s $(pwd)/nvim/init.vim ~/.config/nvim/init.vim
```

## ⚙️ 主な設定内容

- Vim互換の設定
- カスタマイズは `init.vim` を参照

## 📝 カスタマイズ

Neovim固有の機能を使う場合は、`init.vim` に追記してください。
