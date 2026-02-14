---
name: maestro-qa
description: |
  Maestro E2Eテストを実行し、結果をサマリーレポートする。
  「/maestro-qa」「E2Eテスト実行」「QAを回して」「動作確認して」等で発動。
  Flowの新規作成はmaestro-e2eエージェントが担当。このスキルは既存Flowの実行に特化。
user_invocable: true
---

# Maestro QA スキル

既存の Maestro E2E テストフローを実行し、結果をサマリーレポートする定型作業スキル。

## 実行手順

### 1. 前提確認

```bash
# Maestro CLI 存在確認
make maestro-setup

# デバイス接続確認
make maestro-check
```

前提が満たされない場合はユーザーに報告して中断する。

### 2. テスト実行

```bash
# デバッグビルド + 全テスト実行
make maestro-run-all
```

または、ビルド済みの場合:

```bash
# テストのみ実行
make maestro-test
```

### 3. 結果サマリー表示

以下の形式でレポートする:

```
## Maestro E2E テスト結果

| フロー | 結果 |
|--------|------|
| smoke_test | Pass / Fail |
| timer_basic_flow | Pass / Fail |
| timer_break_flow | Pass / Fail |
| project_management | Pass / Fail |

**合計**: X/Y Pass
```

### 4. 失敗時の対応

失敗したフローがある場合:
1. エラーメッセージを表示する
2. スクリーンショットがあれば Gemini で解析を提案する
3. `maestro-e2e` エージェントでの修正を提案する

```
失敗フローの修正が必要です。以下のコマンドで maestro-e2e エージェントを起動できます:
Task tool → maestro-e2e → "timer_basic_flow.yaml が失敗しています。修正してください"
```

## 注意事項

- このスキルは既存フローの **実行のみ** を行う
- 新規フロー作成や Key 付与は `maestro-e2e` エージェントが担当する
- Gemini CLI 呼び出し時は `model: "gemini-3-pro-preview"` を指定する