# VSCode 設定

Visual Studio Codeの設定ファイルです。

## 📄 ファイル

- `settings.json` - VSCode設定ファイル

## 🚀 セットアップ

### macOS

```bash
ln -s $(pwd)/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

### Linux

```bash
ln -s $(pwd)/vscode/settings.json ~/.config/Code/User/settings.json
```

### Windows

```powershell
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Code\User\settings.json" -Target "$(pwd)\vscode\settings.json"
```

## ⚙️ 主な設定内容

- エディタ設定（フォント、タブ幅など）
- ファイル保存時の自動フォーマット
- 拡張機能の設定

詳細は `settings.json` を参照してください。

## 📝 拡張機能

推奨拡張機能のリストは `extensions.json` に記載（今後追加予定）。

## 💡 Tips

設定の同期機能（Settings Sync）を使うと、複数環境での設定管理が簡単になります。