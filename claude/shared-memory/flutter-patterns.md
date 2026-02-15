# Flutter 横断パターン記録

## トランザクション内 WorkDay 取得/作成パターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: トランザクション内で移動先の WorkDay を取得、存在しなければ作成し、エントリの workDayId を更新する。移動元が孤立すれば削除。
- **具体例**: `DriftLogRepository.moveEntryToDate` - addManualEntry と同じ WorkDay 取得/作成ロジックを再利用
- **スキル化済み**: No

## Dialog sealed class 返却型パターン
- **カテゴリ**: 設計
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: ダイアログが複数種類のアクション結果を返す場合、sealed class で型安全に分岐する。sentinel value（-1等）はファイルスコープ内なら許容するが、sealed class のほうが型安全。
- **具体例**: `_EditDialogResult` → `_TimeEditResult` / `_MoveDateResult` in `day_detail_page.dart`; `_DailyGoalDialog` は sentinel value (-1) で「解除」と「キャンセル」(null) を区別
- **スキル化済み**: Yes

## 未来日付バリデーションの二重防御
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: UI 側で DatePicker の lastDate 制限 + Service 層で FutureDateError バリデーション。UI をバイパスする経路に備えた防御的プログラミング。
- **具体例**: `LogServiceImpl.moveEntryToDate` の未来日チェック + `_EntryEditDialog._pickDate` の lastDate: today
- **スキル化済み**: No

## invalidateSelf vs 直接 state 更新の判断
- **カテゴリ**: バグ防止
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: Notifier の操作が「別のデータソースに影響する」場合は invalidateSelf() で再フェッチ、「同じデータソース内の変更」なら直接更新。IndexedStack で複数ページが Widget ツリーに同時存在する場合、操作元の Notifier で関連する全プロバイダを invalidate する必要がある。
- **具体例**: (1) `DayDetailNotifier.moveEntryToDate` - 移動先 entries で state 更新 → 移動元画面と不整合 → invalidateSelf() に修正; (2) `TimerNotifier._invalidateLogProviders()` - `daySummariesProvider` のみ invalidate → `activityBreakdownProvider` / `weeklyBreakdownProvider` も追加が必要だった（E2E テストで発見）
- **スキル化済み**: Yes

## Widget テストで画面外ボタンがタップできない問題
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: UI にコンテンツ（円グラフ等）を追加すると、既存の Widget テストで画面下部のボタンが画面外に押し出されタップ失敗する。`scrollUntilVisible` は複数 Scrollable があると `Too many elements` エラーになる。`tester.view.physicalSize` で画面サイズを拡大する方が安定。
- **具体例**: `log_page_test.dart` の PDF/CSV ボタンテスト - 円グラフ追加で Offset(626.6, 752.0) が画面外 (800x600) に。`tester.view.physicalSize = Size(800, 1600)` + `devicePixelRatio = 1.0` で解決。`addTearDown` で `resetPhysicalSize` / `resetDevicePixelRatio` 必須。
- **スキル化済み**: No

## fl_chart のテスト戦略（PieChart / BarChart）
- **カテゴリ**: テスト
- **遭遇回数**: 3
- **発見元**: time-tracker
- **概要**: fl_chart のチャートは CustomPainter で描画するため、テキスト検索では検出できない。`tester.widget<PieChart/BarChart>(find.byType(...)).data` でチャートデータを直接検証する。BarChart の場合は `barGroups[i].barRods[0].toY` で棒の高さ、`.rodStackItems` でスタック構成を検証する。`extraLinesData.horizontalLines` で目標ライン等の補助線も検証可能。
- **具体例**: `activity_pie_chart_test.dart` - sections を直接アサート; `weekly_stacked_bar_chart_test.dart` - barGroups, rodStackItems, toY を直接アサート; `weekly_stacked_bar_chart_goal_line_test.dart` - horizontalLines の y, color, dashArray, label を検証
- **スキル化済み**: Yes

## FutureProvider.autoDispose + ViewModel 経由の目標達成度パターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Service 不要のケースでは FutureProvider.autoDispose で Repository 単一メソッド + 純粋関数計算（CalculationService）を組み合わせる。稼働中のセッションエントリ（endedAt == null）も考慮するため、timerState.entries との重複排除が必要。
- **具体例**: `dailyGoalProgressProvider` - LogRepository.getEntriesForDate + CalculationService.calculateWorkDuration + timerState.entries の重複排除
- **スキル化済み**: No

## CustomPaint の find.byType テストでの多重マッチ問題
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `find.byType(CustomPaint)` は Scaffold 等のフレームワーク Widget にも含まれるため複数マッチする。`find.descendant(of: find.byType(TargetWidget), matching: find.byType(CustomPaint))` でスコープを限定する必要がある。
- **具体例**: `progress_ring_test.dart` - ProgressRing 内の CustomPaint のみを検証するため descendant を使用
- **スキル化済み**: No

## Drift storeDateTimeAsText と customSelect の組み合わせ
- **カテゴリ**: バグ防止
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: `storeDateTimeAsText: true` の場合、customSelect で日時比較するとき ISO 8601 文字列で比較し、秒差計算には `strftime('%s', col)` を使う。また、`row.read<String>('date_column')` で取得した文字列を `DateTime.parse()` するとUTCとして解析される場合があるため、`.toLocal()` + `DateTime(y,m,d)` で論理日付に変換する必要がある。
- **具体例**: `DriftMonthlyReportRepository.getActivityBreakdown` - Variable.withString, strftime 使用; `getWeeklyBreakdown` - DateTime.parse(dateStr).toLocal() で UTC→ローカル変換
- **スキル化済み**: Yes
