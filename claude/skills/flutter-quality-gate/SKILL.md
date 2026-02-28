---
name: flutter-quality-gate
description: |
  Flutter Layer-first DDDプロジェクトの品質ゲート（テスト + analyze + DDD依存チェック）を一括実行するスキル。
  `scripts/quality-gate.sh PROJECT_ROOT` で3点チェックを一括実行し、結果をサマリー表示する。

  **自動発動条件（flutter-developer / flutter-layer-first-architect が proactively に使用）:**
  - TDD サイクルの Green/Refactor フェーズでテスト実行が必要なとき
  - Architect が interface 作成後にビルド確認するとき
  - 実装完了時の最終品質チェック
  - コミット前の品質確認

  **手動発動条件:**
  - `/flutter-quality-gate` で直接呼び出し
  - 「品質チェック」「テスト実行」「全チェック」等

  **サブエージェントでの使用:**
  flutter-developer / flutter-layer-first-architect のプロンプトに以下を含める:
  `品質チェックは ~/.claude/skills/flutter-quality-gate/scripts/quality-gate.sh PROJECT_ROOT を実行`
---

# Flutter Quality Gate

## 一括チェック

```bash
~/.claude/skills/flutter-quality-gate/scripts/quality-gate.sh PROJECT_ROOT
```

3点チェックを順次実行し、サマリーを表示する:
1. `flutter test` — 全テスト実行（結果を `.claude/tmp/flutter_quality_gate.txt` に保存）
2. `flutter analyze --no-fatal-infos` — 静的解析（error/warning のみ失敗判定、info はスキップ）
3. `script/ddd-dependency-check.sh` — DDD レイヤー依存方向チェック（スクリプトが無ければスキップ）

終了コード 0 = 全通過、1 = いずれか失敗。

## 個別実行

テストのみ高速に回したい場合:

```bash
# 全テスト
flutter test

# 特定ディレクトリ
flutter test test/domain/ranking/

# 特定ファイル
flutter test test/domain/ranking/ranking_name_test.dart
```

## サブエージェントへの組み込み

flutter-developer / flutter-layer-first-architect の Task tool プロンプトに以下を追記:

```
品質チェックコマンド:
  一括: ~/.claude/skills/flutter-quality-gate/scripts/quality-gate.sh PROJECT_ROOT
  テストのみ: flutter test
  解析のみ: flutter analyze --no-fatal-infos
```

## 失敗時の対応

| チェック | 失敗時のアクション |
|---------|------------------|
| flutter test | テスト失敗箇所がサマリーに表示される。`.claude/tmp/flutter_quality_gate.txt` で全出力確認 |
| flutter analyze | error/warning 行が表示される。info は無視して良い |
| DDD依存チェック | 違反ファイル・行番号が表示される。import を修正する |
