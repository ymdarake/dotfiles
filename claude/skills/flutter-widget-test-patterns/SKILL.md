---
name: flutter-widget-test-patterns
description: |
  Flutter Widget テストで頻出する4つの問題パターンと対処法を提供するスキル。
  (1) 画面外ボタンがタップできない問題（ensureVisible / physicalSize 拡大）、
  (2) find.text が複数 Widget にマッチする問題（find.descendant / findsAtLeast）、
  (3) Interface メソッド追加時の Mock スタブ漏れ（setUp デフォルトスタブ / registerFallbackValue）、
  (4) atom ウィジェットの Riverpod 非依存テスト（ProviderScope 不要のラップ）。
  Use when: Widget テストが unexpectedly fail するとき、新しい Mock スタブを追加するとき、
  atom コンポーネントのテストを書くとき。
  「Widget テスト失敗」「find.text マッチ」「Mock スタブ」「atom テスト」等で発動。
---

# Flutter Widget テストパターン

Widget テストで繰り返し遭遇する4つの問題パターンと、それぞれの対処法をまとめたスキル。
詳細なコード例は [references/test-patterns.md](references/test-patterns.md) を参照。

## パターン 1: 画面外ボタンがタップできない問題

### 状況

UI にコンテンツ（テーブル、チャート等）を追加すると、Widget テストのデフォルト画面サイズ（800x600）では画面下部のボタンが画面外に押し出され、`tester.tap()` が失敗する。

### 対処法

**方法 A: 画面サイズ拡大**（複数 Scrollable がある場合に安定）

```dart
setUp(() {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
});

tearDown(() {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
});
```

**方法 B: ensureVisible + pumpAndSettle**（SingleChildScrollView 1つの場合に安定）

```dart
await tester.ensureVisible(find.text('ボタンテキスト'));
await tester.pumpAndSettle();
await tester.tap(find.text('ボタンテキスト'));
```

### 使い分け

| 条件 | 推奨 |
|------|------|
| Scrollable が1つ | `ensureVisible` |
| 複数 Scrollable | 画面サイズ拡大 |
| fl_chart 等の CustomPainter あり | 画面サイズ拡大 |

**注意**: Flutter 3.41.0 では `TestWidgetsFlutterBinding` に `view` getter がなく、`tester.view` を使う。

## パターン 2: find.text が複数 Widget にマッチする問題

### 状況

`find.text('X')` が対象 Widget 以外の別 Widget にもマッチし、`findsOneWidget` が失敗する。
例: EntryTile の「稼働」テキストが DurationSummaryRow にも存在する。

### 対処法

**方法 A: find.descendant でスコープ限定**（特定 Widget 内のテキストを検証する場合）

```dart
expect(
  find.descendant(
    of: find.byType(TargetWidget),
    matching: find.text('X'),
  ),
  findsOneWidget,
);
```

**方法 B: findsAtLeast に変更**（テキストの存在確認だけで十分な場合）

```dart
expect(find.text('X'), findsAtLeast(1));
```

### 使い分け

| 条件 | 推奨 |
|------|------|
| 特定 Widget 内のテキストを厳密に検証 | `find.descendant` |
| テキストがどこかに表示されていれば OK | `findsAtLeast(1)` |

## パターン 3: Interface メソッド追加時の Mock スタブ漏れ

### 状況

domain interface にメソッドを追加すると、mocktail の Mock クラスは未スタブのメソッドに対して null を返す。`Future<bool>` 等の non-nullable 型で `type 'Null' is not a subtype of type 'Future<bool>'` エラーが発生する。

### 対処法

**1. setUp で全 Mock メソッドにデフォルトスタブを設定**

```dart
setUp(() {
  mockService = MockTrackingService();
  // 新規追加メソッドのデフォルトスタブ
  when(() => mockService.requestPermission())
      .thenAnswer((_) async => true);
});
```

**2. 新しい型を使うメソッドの場合は registerFallbackValue**

```dart
setUpAll(() {
  registerFallbackValue(Duration.zero);
  registerFallbackValue(DateTime(2024, 1, 1));
});
```

**3. Provider 追加時はオーバーライドも追加**

```dart
ProviderScope(
  overrides: [
    // 新規追加 Provider のオーバーライドを忘れない
    newRepositoryProvider.overrideWithValue(mockNewRepository),
  ],
  child: const MyApp(),
)
```

### チェックリスト

interface にメソッドを追加したら:

1. `grep -r "Mock<InterfaceName>" test/` で全 Mock 使用箇所を検索
2. 各テストファイルの `setUp` にデフォルトスタブを追加
3. 新しい型パラメータがあれば `setUpAll` に `registerFallbackValue` を追加
4. Provider を追加した場合は `ProviderScope.overrides` にも追加

## パターン 4: atom ウィジェットの Riverpod 非依存テスト

### 状況

Riverpod に依存しない pure widget（atom）をテストする際、不要な ProviderScope を含めてしまうと、テストが肥大化し依存が不明瞭になる。

### 対処法

**ProviderScope なしでラップ**

```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: MyAtomWidget(
        value: testValue,
        onChanged: (v) { captured = v; },
      ),
    ),
  ),
);
```

**コールバック検証は変数キャプチャ**

```dart
Difficulty? selectedValue;
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: DifficultySelector(
        selected: Difficulty.easy,
        onSelect: (d) { selectedValue = d; },
      ),
    ),
  ),
);

await tester.tap(find.text('Hard'));
expect(selectedValue, Difficulty.hard);
```

**選択状態の検証は ancestor で Widget 型を確認**

```dart
// 選択中 = FilledButton、未選択 = OutlinedButton
expect(
  find.ancestor(
    of: find.text('Easy'),
    matching: find.byType(FilledButton),
  ),
  findsOneWidget,
);
```

### 判断基準

| Widget の特性 | テストのラップ方法 |
|--------------|-----------------|
| Provider に依存しない（atom/compound） | `MaterialApp` + `Scaffold` のみ |
| Provider に依存する（page/view_model 連携） | `ProviderScope` + `MaterialApp` |
