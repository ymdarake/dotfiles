---
name: flutter-ddd-review
description: |
  Flutter Layer-first DDDプロジェクトのアーキテクチャレビューをGemini CLIに依頼するスキル。
  依存方向の違反、責務の逸脱、Resultパターンの適用漏れ、interface分離の不備を検出する。

  **手動発動条件:**
  - ユーザーが「DDDレビュー」「アーキテクチャレビュー」「依存方向チェック」等と依頼した場合
  - `/flutter-ddd-review` で直接呼び出し

  **内部呼び出し:**
  - flutter-tdd-cycle スキルのレビューフェーズから呼び出される
user_invocable: true
---

# Flutter DDD Architecture Review

Layer-first DDD風アーキテクチャの違反をGemini CLIでレビューする。

## 前提条件

- Flutter プロジェクトであること
- Layer-first DDD風のディレクトリ構造であること（ui / domain / use_case / infrastructure）

## Workflow

1. Gemini CLIにDDDアーキテクチャレビューを依頼
2. 結果をユーザーに提示
3. 修正を適用（ユーザーが承認した場合）

### Step 1: Send DDD Review to Gemini CLI

`mcp__gemini-cli__chat` にDDDレビュープロンプトを送信する。Gemini が自律的に `git diff` を実行し、必要に応じて変更ファイルを読んでレビューする。

**重要:**
- Claude 側で `git diff` やファイル読み込みは行わない（コンテキスト節約）
- diff の取得・粒度の判断は全て Gemini に委ねる

See [references/ddd-review-prompt.md](references/ddd-review-prompt.md) for the prompt template.

**Call pattern:**

```
mcp__gemini-cli__chat(
  prompt: "<ddd-review-prompt.md のテンプレート>"
)
```

### Step 2: Present Findings

Geminiの指摘をユーザーに提示する。違反種別ごとにグルーピング:

1. **依存方向の違反** (Critical/High)
2. **責務の逸脱** (High/Medium)
3. **Resultパターン未適用** (Medium)
4. **interface分離の不備** (Medium)

### Step 3: Apply Fixes

ユーザーが承認した指摘について修正を適用する:

1. 依存方向の違反 → import を正しい層に変更
2. 責務の逸脱 → ロジックを適切な層に移動
3. Resultパターン → 例外を Result に変換
4. interface分離 → domain に interface を抽出

修正後、テストが通ることを確認:

```bash
flutter test
```

## Resources

### references/

- **[ddd-review-prompt.md](references/ddd-review-prompt.md)**: DDDアーキテクチャレビュー用のプロンプトテンプレート
