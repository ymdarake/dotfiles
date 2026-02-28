---
name: gemini-code-review
description: |
  Send review request to Gemini CLI (mcp__gemini-cli__chat) for code review, then apply fixes with TDD.

  **自動発動条件（以下のいずれかに該当する場合、ユーザーの明示的な指示がなくても自動的にこのスキルを実行する）:**
  - 新しいモジュール、機能、アーキテクチャを設計・実装した場合
  - 大規模な変更（100行以上の差分）を行った場合
  - Stop hookから「Geminiコードレビューを実行してください」と指示された場合

  **手動発動条件:**
  - ユーザーが "geminiにレビューしてもらって", "Geminiでコードレビュー", "geminiレビュー" 等と依頼した場合
  - 外部AIにコードレビューを依頼したい場合
---

# Gemini Code Review

Send review request to Gemini CLI, let Gemini handle diff collection and review autonomously, then apply fixes with TDD.

## Workflow

1. Send review request to Gemini CLI
2. Present findings to user
3. Apply fixes with TDD (if user approves)

### Step 1: Send Review to Gemini CLI

Use `mcp__gemini-cli__chat` with a review prompt. Gemini が自律的に `git diff` を実行し、必要に応じて変更ファイルを読んでレビューする。

**重要:**
- Claude 側で `git diff` やファイル読み込みは行わない（コンテキスト節約）
- diff の取得・粒度の判断は全て Gemini に委ねる
- `~/.gemini/settings.json` の `tools.allowed` で `git` コマンドを許可済み

See [references/review-prompts.md](references/review-prompts.md) for prompt templates by review type.

**Call pattern:**

```
mcp__gemini-cli__chat(
  prompt: "<review-prompts.md のテンプレート>",
  model: "gemini-3.1-pro-preview"
)
```

**フォールバック:** `gemini-3.1-pro-preview` が利用できない場合（エラー、タイムアウト等）は `"gemini-3-flash-preview"` を使用する。

### Step 2: Present Findings

Summarize Gemini's findings to the user, grouped by severity (High → Medium → Low). Ask if they want to apply fixes.

### Step 3: Apply Fixes with TDD

For each accepted fix:
1. **Red**: Write a test that exposes the issue
2. **Green**: Apply the minimal fix to pass
3. **Refactor**: Clean up if needed
4. Run full test suite to confirm no regressions

## Resources

### references/

- **[review-prompts.md](references/review-prompts.md)**: Prompt templates for different review types (security-focused, performance-focused, general)
