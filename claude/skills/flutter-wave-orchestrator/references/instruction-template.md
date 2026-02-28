# INSTRUCTION.md テンプレート

PO が各 worktree ルートに配置する Developer への指示書フォーマット。

---

```markdown
---
story_id: STORY-XXX
po_tmux_target: "<session>:<window>.<pane>"
wave_plan: doc/plan/WAVE_{YYYYMMDD}.md
impact_analysis: doc/plan/STORY-XXX.md
---

# 実装指示書: [STORY-XXX] <タイトル>

## ストーリー

As a <ロール>,
I want to <やりたいこと>,
So that <理由>

## 受け入れ条件

<Gherkin AC をここに貼り付け>

## 影響分析

`doc/plan/STORY-XXX.md` を Read で参照してください。

## Wave 計画書

`doc/plan/WAVE_{YYYYMMDD}.md` の、あなたが担当する Wave セクションを参照してください。

## 実装手順

1. `// TODO(developer): STORY-XXX` マーカーを検索して実装箇所を把握
2. interface に対するテストを書く（Red）
3. TODO を実装してテストを通す（Green）
4. リファクタリング（Refactor）
5. `dart analyze` + `flutter test` で品質確認

## 注意事項

- このストーリーのスコープ外の変更はしない
- 共有 interface に不足がある場合は、report.md に `interface_insufficient: true` を記載して報告

## 完了時の作業

### 1. report.md の作成

worktree ルートに `report.md` を Write で作成してください。
フォーマットは以下に従ってください:

\`\`\`yaml
---
story_id: STORY-XXX
result: success | failure | blocked
dart_analyze: pass | fail
flutter_test: pass | fail
tests_passed: <N>
tests_failed: <N>
critical_issues: <N>
high_issues: <N>
interface_insufficient: false
---
\`\`\`

本文には以下を記載:
- 変更ファイル一覧
- AC カバレッジ（各 AC に対応するテストケース）
- 未解決の問題（あれば）

### 2. PO への完了通知

report.md を書き終えたら、以下のコマンドで PO に通知してください:

\`\`\`bash
tmux send-keys -t <po_tmux_target> C-c
tmux send-keys -t <po_tmux_target> -l '[STORY-XXX] 完了。Read <worktree-absolute-path>/report.md'
tmux send-keys -t <po_tmux_target> Enter
\`\`\`

- `<po_tmux_target>` は YAML Frontmatter の `po_tmux_target` の値を使用
- `<worktree-absolute-path>` は `pwd` の出力を使用
```
