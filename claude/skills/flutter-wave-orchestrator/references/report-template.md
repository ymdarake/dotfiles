# report.md テンプレート

Developer が各 worktree ルートに作成する完了報告書フォーマット。
PO が品質ゲート判定に使用する。

---

```markdown
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

# 完了報告: [STORY-XXX] <タイトル>

## 変更ファイル一覧

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `lib/domain/xxx.dart` | 新規 | <概要> |
| `lib/application/xxx.dart` | 修正 | <概要> |
| `test/xxx_test.dart` | 新規 | <概要> |

## AC カバレッジ

| AC | テストケース | 結果 |
|----|------------|------|
| Given ... When ... Then ... | `test('...')` in xxx_test.dart | Pass |
| Given ... When ... Then ... | `test('...')` in xxx_test.dart | Pass |

## セルフレビュー結果

- [ ] DDD レイヤー境界の遵守
- [ ] 依存方向の正しさ（domain ← application ← presentation）
- [ ] Result パターンの適用
- [ ] テストの網羅性

## 未解決の問題

（なければ「なし」）
```

## PO の品質ゲート判定基準

YAML Frontmatter の以下を確認:

| フィールド | 合格条件 |
|-----------|---------|
| `result` | `success` |
| `dart_analyze` | `pass` |
| `flutter_test` | `pass` |
| `critical_issues` | `0` |
| `high_issues` | `0` |
| `interface_insufficient` | `false` |

`interface_insufficient: true` の場合は Architect に差し戻し。
