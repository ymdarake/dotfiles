# Vim 設定

Vimの設定ファイルとプラグイン管理です。

## 📄 ファイル

- `.vimrc` - Vim設定ファイル

## 🚀 セットアップ

### 1. vim-plug のインストール

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### 2. カラースキームのインストール

```bash
git clone https://github.com/tomasiser/vim-code-dark.git ~/.vim/bundle/vim-code-dark.git
mkdir -p ~/.vim/colors
ln -s ~/.vim/bundle/vim-code-dark.git/colors/codedark.vim ~/.vim/colors/codedark.vim
```

### 3. .vimrc のシンボリックリンク作成

```bash
ln -s $(pwd)/vim/.vimrc ~/.vimrc
```

### 4. プラグインのインストール

```bash
vim
:PlugInstall
```

## ⚙️ 主な設定内容

### 基本設定

- 行番号表示
- シンタックスハイライト
- タブ幅: 2スペース
- インデント自動設定

### プラグイン

- vim-plug によるプラグイン管理
- カラースキーム: codedark

### キーマッピング

- `.vimrc` を参照

## 📝 カスタマイズ

プラグインを追加する場合は、`.vimrc` の `call plug#begin()` と `call plug#end()` の間に追記してください。
