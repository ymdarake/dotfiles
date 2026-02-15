---
name: flutter-fl-chart-test
description: |
  fl_chart パッケージ（PieChart / BarChart）を使ったチャート Widget のテスト戦略スキル。
  CustomPainter で描画されるため find.text() では検証できないチャートデータを、
  tester.widget(find.byType(PieChart)).data 等で直接取得して検証する手法を提供する。
  Use when: (1) fl_chart の PieChart や BarChart を含む Widget テストを書くとき、
  (2) チャートの sections / barGroups / rodStackItems / extraLinesData を検証したいとき、
  (3) チャート追加で画面外に押し出されたボタンのテストが失敗したとき。
  「チャートのテスト」「PieChart テスト」「BarChart テスト」「fl_chart テスト」等で発動。
---

# fl_chart テスト戦略

fl_chart のチャートは CustomPainter で描画されるため、`find.text()` では検証できない。
`tester.widget<ChartType>(find.byType(...)).data` でチャートデータを直接取得して検証する。

## PieChart の検証

```dart
// PieChart の sections を直接取得して検証
final pieChart = tester.widget<PieChart>(find.byType(PieChart));
final sections = pieChart.data.sections;

expect(sections, hasLength(3));
expect(sections[0].value, closeTo(60.0, 0.01));
expect(sections[0].color, Colors.blue);
expect(sections[0].title, '60%');
```

## BarChart の検証

### 棒の高さ（barRods）

```dart
final barChart = tester.widget<BarChart>(find.byType(BarChart));
final barGroups = barChart.data.barGroups;

expect(barGroups, hasLength(7)); // 7日分
expect(barGroups[0].barRods[0].toY, closeTo(3.5, 0.01)); // 棒の高さ
```

### スタック構成（rodStackItems）

```dart
final rod = barGroups[0].barRods[0];
expect(rod.rodStackItems, hasLength(2)); // 2種類のスタック
expect(rod.rodStackItems[0].fromY, 0);
expect(rod.rodStackItems[0].toY, closeTo(2.0, 0.01));
expect(rod.rodStackItems[1].fromY, closeTo(2.0, 0.01));
expect(rod.rodStackItems[1].toY, closeTo(3.5, 0.01));
```

### 補助線（extraLinesData）

```dart
final horizontalLines = barChart.data.extraLinesData?.horizontalLines;
expect(horizontalLines, isNotNull);
expect(horizontalLines!, hasLength(1));
expect(horizontalLines[0].y, closeTo(8.0, 0.01)); // 目標ライン
expect(horizontalLines[0].color, Colors.red);
expect(horizontalLines[0].dashArray, [5, 5]);
```

## 画面外ボタン問題の回避

チャートを追加すると画面下部の要素が画面外（デフォルト 800x600）に押し出され、タップが失敗する場合がある。
`scrollUntilVisible` は複数 Scrollable があると `Too many elements` エラーになるため、画面サイズ拡大が安定する。

```dart
setUp(() {
  // テスト用に画面サイズを拡大
  binding.view.physicalSize = const Size(800, 1600);
  binding.view.devicePixelRatio = 1.0;
});

tearDown(() {
  binding.view.resetPhysicalSize();
  binding.view.resetDevicePixelRatio();
});
```

**注意**: `addTearDown` または `tearDown` で必ずリセットすること。リセットしないと後続テストに影響する。

## テスト設計の指針

1. **データ検証優先**: 見た目（色、サイズ）より**データの正確性**を最優先で検証
2. **境界値**: 0件データ、1件データ、大量データでの表示崩れ
3. **状態遷移**: データ変更後のチャート再描画（`pumpAndSettle` で待機）
4. **複数チャート**: 同一画面に複数チャートがある場合は `find.descendant` でスコープ限定
