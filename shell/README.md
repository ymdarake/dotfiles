# Shell 設定

シェル（zsh, bash）の設定ファイルです。

## 📄 ファイル

- `.zshrc` - zsh設定ファイル
- `.bash_profile` - bash設定ファイル

## 🚀 セットアップ

### zsh

```bash
ln -s $(pwd)/shell/.zshrc ~/.zshrc
source ~/.zshrc
```

### bash

```bash
ln -s $(pwd)/shell/.bash_profile ~/.bash_profile
source ~/.bash_profile
```

## ⚙️ 主な設定内容

### エイリアス

- `ll` - `ls -la` の短縮形
- `..` - 親ディレクトリへ移動
- `...` - 2つ上のディレクトリへ移動

### パス設定

- Homebrewのパス
- 各種開発ツールのパス

### プロンプト設定

- Gitブランチ名の表示
- カレントディレクトリの表示

## 📝 カスタマイズ

個人的な設定は `.zshrc.local` などに分離することをおすすめします：

```bash
# .zshrc の最後に追加
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```
