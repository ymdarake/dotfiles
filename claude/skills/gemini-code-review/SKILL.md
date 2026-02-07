---
name: gemini-code-review
description: |
  Collect changed files and send them to Gemini CLI (mcp__gemini-cli__chat) for code review, then apply fixes with TDD.

  **自動発動条件（以下のいずれかに該当する場合、ユーザーの明示的な指示がなくても自動的にこのスキルを実行する）:**
  - 新しいモジュール、機能、アーキテクチャを設計・実装した場合
  - 大規模な変更（100行以上の差分）を行った場合
  - Stop hookから「Geminiコードレビューを実行してください」と指示された場合

  **手動発動条件:**
  - ユーザーが "geminiにレビューしてもらって", "Geminiでコードレビュー", "geminiレビュー" 等と依頼した場合
  - 外部AIにコードレビューを依頼したい場合
---

# Gemini Code Review

Collect code changes, send to Gemini CLI for review, and apply identified fixes using TDD.

## Workflow

1. Collect changed files
2. Read file contents
3. Send review request to Gemini CLI
4. Present findings to user
5. Apply fixes with TDD (if user approves)

### Step 1: Collect Changed Files

Determine what to review based on context:

- **Staged/unstaged changes**: Run `git diff` and `git diff --cached` to get changed files
- **Branch changes**: Run `git diff main...HEAD` (or appropriate base branch)
- **Specific files**: If user specifies files, use those directly

List the files and confirm scope with user if ambiguous.

### Step 2: Read File Contents

Read all changed files using the Read tool. For large diffs, focus on the most impactful files first.

### Step 3: Send Review to Gemini CLI

Use `mcp__gemini-cli__chat` with a structured prompt. See [references/review-prompts.md](references/review-prompts.md) for prompt templates by review type.

**Default review prompt structure:**

```
以下のコード変更をレビューしてください。

## レビュー観点
- セキュリティ（インジェクション、認証、権限）
- バグ・ロジックエラー
- パフォーマンス
- エラーハンドリング

## 出力形式
各指摘を以下の形式で:
- **重要度**: High / Medium / Low
- **ファイル**: ファイルパス
- **問題**: 具体的な問題
- **修正案**: 具体的な修正コード

## コード
[file contents here]
```

### Step 4: Present Findings

Summarize Gemini's findings to the user, grouped by severity (High → Medium → Low). Ask if they want to apply fixes.

### Step 5: Apply Fixes with TDD

For each accepted fix:
1. **Red**: Write a test that exposes the issue
2. **Green**: Apply the minimal fix to pass
3. **Refactor**: Clean up if needed
4. Run full test suite to confirm no regressions

## Resources

### references/

- **[review-prompts.md](references/review-prompts.md)**: Prompt templates for different review types (security-focused, performance-focused, general)
