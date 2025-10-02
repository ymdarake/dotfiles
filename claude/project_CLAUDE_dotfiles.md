# プロジェクト設定 (dotfiles)

dotfilesリポジトリ用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

個人の開発環境設定（dotfiles）を管理するリポジトリです。

## ディレクトリ構成

- `shell/` - シェル設定（.zshrc等）
- `vim/` - Vim設定
- `nvim/` - Neovim設定
- `git/` - Git設定
- `tmux/` - tmux設定
- `vscode/` - VSCode設定
- `ssh/` - SSH設定
- `claude/` - Claude Code設定サンプル

## コーディングスタイル

- シェルスクリプト: shellcheck でチェック
- コメントは日本語可
- 各ディレクトリに README.md を配置
- 設定の適用方法を明記

## セットアップコマンド

各設定ファイルは基本的にシンボリックリンクで適用：

```bash
# 例: zsh設定
ln -s $(pwd)/shell/.zshrc ~/.zshrc

# 例: git設定
ln -s $(pwd)/git/.gitconfig ~/.gitconfig

# 例: Claude Code設定
ln -s $(pwd)/claude/global_CLAUDE.md ~/.claude/CLAUDE.md
```

## Git運用

- コミットメッセージは日本語
- gitmoji を使用
  - `:wrench:` 設定変更
  - `:sparkles:` 新機能追加
  - `:memo:` ドキュメント更新
  - `:recycle:` リファクタリング
- 変更は小さく頻繁にコミット

## セキュリティ

- **秘密情報は絶対にコミットしない**
- SSH秘密鍵、トークン等は除外
- `.gitconfig` にメールアドレスを含む場合は注意
- サンプルファイル（`.example`）を用意し、実際の設定は `.gitignore`

## 追加する設定

新しい設定を追加する際：

1. 専用ディレクトリを作成
2. README.md で説明を記載
3. サンプルファイルを用意
4. シンボリックリンクコマンドを明記

## このリポジトリのルール

- 各設定ファイルには説明コメントを追加
- 他の環境でも動作するように汎用的に記述
- 環境依存の設定は別ファイルに分離

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*
