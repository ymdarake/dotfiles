---
name: maestro-qa
description: |
  Maestro E2Eテストの実行コマンドを提示し、結果を受けて対応する。
  「/maestro-qa」「E2Eテスト実行」「QAを回して」「動作確認して」等で発動。
  Flowの新規作成はmaestro-e2eエージェントが担当。このスキルは既存Flowの実行支援に特化。
user_invocable: true
---

# Maestro QA スキル

既存の Maestro E2E テストフローの実行コマンドを提示し、ユーザーからの結果報告に基づいて対応する。

## 実行手順

### 1. フロー一覧の確認

`.maestro/flows/` 以下の既存フローを確認し、ユーザーに実行対象を案内する。

### 2. 実行コマンドの提示

**エージェント自身はテストを実行しない。** 以下のコマンドをユーザーに提示する。

```bash
# 全フロー実行 (Debug ビルド、日常開発向け、~2分)
make maestro-test

# 安定テスト実行 (ADB再起動 + アニメーション無効化 + テスト)
make maestro-test-fast

# 単一フロー実行
make maestro-test-flow FLOW=<flow_name>.yaml

# デバッグビルド→APKインストール→事前設定→全テスト実行
make maestro-run-all
```

**推奨**: 日常開発では `make maestro-test` で十分（High-End AVD で ~2分）。
`device offline` エラーが発生する場合は `make maestro-test-fast` を使う（ADB 再起動を内蔵）。

初回実行時やエミュレータ再起動後は、事前設定も案内する:

```bash
make maestro-prepare  # エミュレータの E2E 向け事前設定（スタイラス手書き無効化等）
```

### 3. テスト結果の受領と対応

ユーザーからテスト結果（ターミナル出力やスクリーンショット）を受け取り、以下の形式でサマリーする:

```
## Maestro E2E テスト結果

| フロー | 結果 |
|--------|------|
| smoke_test | Pass / Fail |
| timer_basic_flow | Pass / Fail |
| ...    | ...  |

**合計**: X/Y Pass
```

### 4. 失敗時の対応

失敗したフローがある場合:
1. エラーメッセージを分析する
2. スクリーンショットがあれば Gemini で解析する
3. 修正が必要な場合は `maestro-e2e` エージェントでの修正を提案する

```
失敗フローの修正が必要です。以下のコマンドで maestro-e2e エージェントを起動できます:
Task tool → maestro-e2e → "timer_basic_flow.yaml が失敗しています。修正してください"
```

## 注意事項

- このスキルは **テスト実行コマンドの提示と結果分析** を行う（テスト自体は実行しない）
- 新規フロー作成や Key 付与は `maestro-e2e` エージェントが担当する
- Gemini CLI 呼び出し時は `model: "gemini-3-pro-preview"` を指定する