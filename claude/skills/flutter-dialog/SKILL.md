---
name: flutter-dialog
description: |
  Flutterダイアログを定型パターンで生成する。
  テキスト入力、時刻範囲選択、確認、選択、複数アクション結果（sealed class）など
  各種ダイアログパターンの実装ガイドを提供する。
  Use when: (1) 新しいダイアログを作成するとき、(2) ダイアログが複数種類の結果を返す設計が必要なとき
  （sealed class vs sentinel value の選定）、(3) showDialog の統合パターンを確認したいとき。
  「ダイアログ作って」「入力ダイアログ追加」「確認ダイアログ必要」
  「〜ダイアログを実装して」等で発動。
  StatefulWidget + showDialog パターンに準拠し、TDDで実装する。
---

# Flutter Dialog

Flutterダイアログを定型パターンで一貫性のある実装にするスキル。

## パターン選択ガイド

要件に応じて以下から選択する:

| パターン | 返却型 | 用途 |
|---------|-------|------|
| テキスト入力 | `String?` | 名前入力、メモなど単一テキスト |
| 時刻範囲選択 | `({DateTime start, DateTime end})?` | 開始/終了時刻の編集 |
| 複数入力フォーム | Named record? | 種別+時刻など複合入力 |
| 確認 | `bool?` | 削除確認などYes/No |
| 選択 | `T?` | リストから1つ選択 |
| 複数アクション結果 | `sealed class?` | 編集/移動/削除など複数種類のアクションを返す |

## 実装原則

1. **ダイアログはUI+入力管理のみ** — ビジネスロジック・Repository呼び出しは呼び出し側で行う
2. **値を返す** — `Navigator.pop(context, value)` で結果を返却。キャンセル時は `null`
3. **リソース解放** — `TextEditingController` 等は `dispose()` で必ず破棄
4. **context.mounted** — `await` 後のUI操作前に必ずチェック
5. **バリデーション** — ダイアログ内で `String? _error` + `setState` でローカルエラー表示
6. **private class** — ダイアログクラスは `_` prefix でファイルスコープに限定

## 複数アクション結果の返却（sealed class パターン）

ダイアログが「編集」「移動」「削除」など複数種類のアクション結果を返す場合、sealed class で型安全に分岐する。

### sealed class 定義

```dart
// ファイルスコープで定義
sealed class _EditDialogResult {}
class _TimeEditResult extends _EditDialogResult {
  final DateTime start;
  final DateTime end;
  _TimeEditResult({required this.start, required this.end});
}
class _MoveDateResult extends _EditDialogResult {
  final DateTime targetDate;
  _MoveDateResult({required this.targetDate});
}
```

### ダイアログからの返却

```dart
// 編集ボタン
Navigator.pop(context, _TimeEditResult(start: _start, end: _end));

// 移動ボタン
Navigator.pop(context, _MoveDateResult(targetDate: picked));
```

### 呼び出し側での分岐

```dart
final result = await showDialog<_EditDialogResult>(
  context: context,
  builder: (_) => _EntryEditDialog(entry: entry),
);
if (result == null) return; // キャンセル

switch (result) {
  case _TimeEditResult(:final start, :final end):
    await ref.read(notifier).updateTime(start, end);
  case _MoveDateResult(:final targetDate):
    await ref.read(notifier).moveToDate(targetDate);
}
```

### sentinel value との使い分け

| 方式 | 使いどころ |
|------|-----------|
| **sealed class** | アクション種別が2つ以上、データ構造が異なる場合 |
| **sentinel value** (`-1` 等) | 単一型で「解除」と「キャンセル」を区別する程度の場合（ファイルスコープ内に限定） |

## 呼び出し側の統合パターン

```dart
// 1. ダイアログ表示 → null チェック
final result = await showDialog<ReturnType>(
  context: context,
  builder: (_) => const _XxxDialog(...),
);
if (result == null) return;

// 2. Riverpod経由でビジネスロジック実行
final opResult = await ref.read(xxxProvider.notifier).doSomething(result);

// 3. context.mounted チェック → Result処理
if (context.mounted) {
  switch (opResult) {
    case Success(): break;
    case Failure(error: final e): showErrorSnackBar(context, e);
  }
}
```

## TDDワークフロー

1. **Red** — Widget テストを書く（`pumpWidget` + `tap` + `expect`）
2. **Green** — テンプレートベースで最小実装
3. **Refactor** — 不要コード削除、命名改善

テスト例:
```dart
testWidgets('ダイアログがキャンセルでnullを返す', (tester) async {
  String? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showDialog<String>(
            context: context,
            builder: (_) => const _XxxDialog(),
          );
        },
        child: const Text('open'),
      );
    }),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('キャンセル'));
  await tester.pumpAndSettle();
  expect(result, isNull);
});
```

## 参照

各パターンの完全なコードテンプレートは `references/dialog-patterns.md` を参照。
