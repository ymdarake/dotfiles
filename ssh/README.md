# SSH 設定

SSHクライアントの設定ファイルです。

## 📄 ファイル

- `config` - SSH設定ファイル

## 🚀 セットアップ

### 1. .sshディレクトリの作成

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### 2. config のシンボリックリンク作成

```bash
ln -s $(pwd)/ssh/config ~/.ssh/config
chmod 600 ~/.ssh/config
```

## ⚙️ 主な設定内容

- ホストごとの接続設定
- 鍵ファイルの指定
- 接続オプション

詳細は `config` を参照してください。

## 🔒 セキュリティ

**重要:** SSH秘密鍵は絶対にリポジトリにコミットしないでください。

- 秘密鍵は `~/.ssh/` に直接配置
- パーミッションを適切に設定 (`chmod 600`)
- 公開鍵のみを管理対象にする場合も注意

## 📝 カスタマイズ

新しいホストを追加する場合は、以下の形式で追記：

```
Host example
    HostName example.com
    User username
    IdentityFile ~/.ssh/id_ed25519
    Port 22
```

## 💡 Tips

- `ssh-keygen -t ed25519` で鍵ペアを生成
- `ssh-copy-id` で公開鍵をサーバーに配置
- `ssh-add` で鍵をエージェントに追加
