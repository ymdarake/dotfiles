# Gemini CLI 設定

Gemini CLI (`gemini-cli`) の設定ファイルを管理します。

## ファイル構成

- `settings.json` - Gemini CLI の設定（ツール許可設定など）

## セットアップ

```bash
ln -s $(pwd)/gemini/settings.json ~/.gemini/settings.json
```

## 注意事項

以下のファイルは秘匿情報を含むため、dotfiles では管理しません:

- `oauth_creds.json` - OAuth 認証情報
- `google_accounts.json` - Google アカウント情報
- `installation_id` - インストール固有 ID
