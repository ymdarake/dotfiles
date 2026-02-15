# tmux 設定

tmuxの設定ファイルとスクリプトです。

## 📄 ファイル

- `.tmux.conf` - tmux設定ファイル
- `start-tmux.sh` - tmux起動スクリプト（VSCode連携用）
- `tutorial.md` - 操作チュートリアル（カスタムキーバインド対応 + Wave 開発向け CLI コマンド）

## 🚀 セットアップ

### 1. tmuxのインストール

```bash
brew install tmux
```

### 2. .tmux.conf のシンボリックリンク作成

```bash
ln -s $(pwd)/tmux/.tmux.conf ~/.tmux.conf
```

### 3. tmuxの再起動

```bash
tmux kill-server
tmux
```

## ⚙️ 主な設定内容

### プレフィックスキー

- Prefix: `q` (デフォルトの `Ctrl-b` から変更)

### キーバインド

- `.tmux.conf` を参照

### その他の設定

- マウス操作有効化
- ペインの分割キーバインド
- ステータスバーのカスタマイズ

## 📝 VSCode連携

`start-tmux.sh` を使用すると、VSCodeの統合ターミナルでtmuxを起動できます。

## 📚 参考

- [tmux cheat sheet](https://tmuxcheatsheet.com/)
