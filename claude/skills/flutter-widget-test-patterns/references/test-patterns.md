# Widget テストパターン 詳細リファレンス

SKILL.md の4パターンについて、実プロジェクトでの具体例と詳細な対処法を記載する。

## 1. 画面外ボタン問題 — 詳細

### 発生メカニズム

Flutter Widget テストのデフォルト画面サイズは 800x600。テーブル、チャート、リスト等を追加すると画面下部の要素が領域外に移動し、`tester.tap()` が `hitTestable` チェックで失敗する。

### 方法 A: physicalSize 拡大（完全版）

```dart
testWidgets('画面下部のボタンをタップできる', (tester) async {
  // 画面サイズを拡大
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(const MaterialApp(home: MyPage()));
  await tester.pumpAndSettle();

  // 画面下部のボタンが見える
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();
  expect(find.text('保存完了'), findsOneWidget);
});
```

### 方法 B: ensureVisible（完全版）

```dart
testWidgets('スクロールしてボタンをタップ', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: MyPage()));
  await tester.pumpAndSettle();

  final buttonFinder = find.text('次へ');
  await tester.ensureVisible(buttonFinder);
  await tester.pumpAndSettle();
  await tester.tap(buttonFinder);
  await tester.pumpAndSettle();

  expect(find.text('完了'), findsOneWidget);
});
```

### Flutter バージョン互換性

| API | Flutter 3.41.0 | Flutter 3.x (旧) |
|-----|---------------|-------------------|
| `tester.view.physicalSize` | OK | OK |
| `binding.view.physicalSize` | NG (getter なし) | OK |
| `TestWidgetsFlutterBinding.instance.view` | NG | OK |

**推奨**: 常に `tester.view` を使用する。

---

## 2. find.text 多重マッチ問題 — 詳細

### 典型的なエラーメッセージ

```
Expected: exactly one matching node in the widget tree
  Actual: <two widgets with text "稼働": ...>
```

### find.descendant の応用例

```dart
// TargetWidget 内の特定テキストのみを検証
expect(
  find.descendant(
    of: find.byType(EntryTile),
    matching: find.text('稼働'),
  ),
  findsOneWidget,
);

// Key を使ったスコープ限定
expect(
  find.descendant(
    of: find.byKey(const Key('summary-section')),
    matching: find.text('合計'),
  ),
  findsOneWidget,
);
```

### find.widgetWithText の活用

```dart
// 特定の Widget 型 + テキストの組み合わせ
expect(
  find.widgetWithText(ElevatedButton, '送信'),
  findsOneWidget,
);
```

---

## 3. Mock スタブ漏れ問題 — 詳細

### 典型的なエラーメッセージ

```
type 'Null' is not a subtype of type 'Future<bool>'
type 'Null' is not a subtype of type 'Future<Result<void, TrackingError>>'
```

### 対処パターン A: setUp にデフォルトスタブ追加

```dart
late MockNotificationService mockNotification;

setUp(() {
  mockNotification = MockNotificationService();
  // 新規追加メソッドのデフォルト: 成功を返す
  when(() => mockNotification.requestPermission())
      .thenAnswer((_) async => true);
  when(() => mockNotification.showNotification(any(), any()))
      .thenAnswer((_) async {});
});
```

### 対処パターン B: registerFallbackValue

```dart
setUpAll(() {
  // Duration 型を any() で使う場合に必要
  registerFallbackValue(Duration.zero);
  // DateTime 型を any() で使う場合に必要
  registerFallbackValue(DateTime(2024, 1, 1));
  // カスタム型の場合
  registerFallbackValue(const ActivityData(id: 0, name: '', colorValue: 0));
});
```

### 対処パターン C: ProviderScope.overrides の追加

```dart
// 新しい Repository Provider を追加した場合
Widget buildTestApp() {
  return ProviderScope(
    overrides: [
      serviceProvider.overrideWithValue(mockService),
      // ↓ 新規追加の Provider
      rankingRepositoryProvider.overrideWithValue(mockRankingRepo),
    ],
    child: const MaterialApp(home: MyPage()),
  );
}
```

### 影響範囲の特定手順

```bash
# 1. 追加した interface のMock使用箇所を全検索
grep -r "Mock<InterfaceName>" test/

# 2. ProviderScope.overrides の使用箇所を検索
grep -r "overrides:" test/

# 3. テスト実行で影響範囲を確認
flutter test --reporter compact 2>&1 | grep "FAILED"
```

---

## 4. atom Riverpod 非依存テスト — 詳細

### atom テストの基本構造

```dart
void main() {
  Widget buildSubject({
    Difficulty? selectedDifficulty,
    ValueChanged<Difficulty>? onSelect,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DifficultySelector(
          selectedDifficulty: selectedDifficulty,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    );
  }

  group('DifficultySelector', () {
    testWidgets('選択状態が正しく表示される', (tester) async {
      await tester.pumpWidget(buildSubject(
        selectedDifficulty: Difficulty.easy,
      ));

      // FilledButton = 選択中, OutlinedButton = 未選択
      expect(
        find.ancestor(
          of: find.text('かんたん'),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('ふつう'),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('タップでコールバックが呼ばれる', (tester) async {
      Difficulty? selected;
      await tester.pumpWidget(buildSubject(
        selectedDifficulty: Difficulty.easy,
        onSelect: (d) { selected = d; },
      ));

      await tester.tap(find.text('むずかしい'));
      expect(selected, Difficulty.hard);
    });
  });
}
```

### 表示専用 atom のテスト

```dart
// RulesDisplay のようにコールバックがない atom
testWidgets('ルールが正しく表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RulesDisplay(rules: testRules),
        ),
      ),
    ),
  );

  expect(find.text('ルール1の内容'), findsOneWidget);
  expect(find.text('ルール2の内容'), findsOneWidget);
});
```

### ProviderScope が必要な場合との判断

```
atom/compound Widget
  └─ コンストラクタ引数で全データ受け取り → ProviderScope 不要
  └─ ref.watch / ref.read を使用 → ProviderScope 必要（※ atom の設計を見直すべき）

page Widget
  └─ ViewModel と連携 → ProviderScope 必要
```
