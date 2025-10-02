# Git 設定

Gitの設定ファイルとエイリアスです。

## 📄 ファイル

- `.gitconfig` - Git設定ファイル（個人情報を含むため.gitignore推奨）
- `.gitconfig.example` - 設定ファイルのサンプル

## 🚀 セットアップ

### 1. 設定ファイルの作成

```bash
cp git/.gitconfig.example git/.gitconfig
vim git/.gitconfig  # 名前とメールアドレスを設定
```

### 2. シンボリックリンク作成

```bash
ln -s $(pwd)/git/.gitconfig ~/.gitconfig
```

## ⚙️ 主な設定内容

### エイリアス

- `st` - status
- `lg` - きれいなログ表示
- `ck` - checkout
- `cm` - commit -m
- `br` - branch
- `ft` - fetch --all --prune
- `delbr` - マージ済みブランチを一括削除

### その他の設定

- デフォルトエディタ: vim
- HTTPS の代わりに SSH を使用

## 📝 カスタマイズ

個人情報（名前、メールアドレス）は必ず `.gitconfig` で設定してください。
