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
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: UI 側で DatePicker の lastDate 制限 + Service 層で FutureDateError / FutureStartTimeError バリデーション。UI をバイパスする経路に備えた防御的プログラミング。
- **具体例**: (1) `LogServiceImpl.moveEntryToDate` の未来日チェック + `_EntryEditDialog._pickDate` の lastDate: today; (2) `LogServiceImpl.updateRunningEntryStartTime` の FutureStartTimeError + TimePicker は過去時刻のみ選択可能な想定
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
- **遭遇回数**: 3
- **発見元**: time-tracker, shisoku-flutter
- **概要**: UI にコンテンツ（テーブル、チャート等）を追加すると、既存の Widget テストで画面下部のボタンが画面外に押し出されタップ失敗する。対処法は2つ: (1) `tester.view.physicalSize` で画面サイズを拡大（Flutter 3.x の一部バージョンでは `binding.view` が使えず `tester.view` を使う必要あり）、(2) `ensureVisible` + `pumpAndSettle` でスクロール。SingleChildScrollView 1つの場合は `ensureVisible` が安定。複数 Scrollable がある場合は画面サイズ拡大の方が安定。
- **具体例**: (1) `log_page_test.dart` の PDF/CSV ボタンテスト - 円グラフ追加で画面外に。`tester.view.physicalSize = Size(800, 1600)` で解決。(2) `end_page_test.dart` - ResultTable 10行でボタンが画面外に。`ensureVisible(find.text('もう一度'))` + `pumpAndSettle` で解決。Flutter 3.41.0 では `TestWidgetsFlutterBinding` に `view` getter がなく、`tester.view` を使う必要あり。
- **スキル化済み**: Yes

## fl_chart のテスト戦略（PieChart / BarChart）
- **カテゴリ**: テスト
- **遭遇回数**: 3
- **発見元**: time-tracker
- **概要**: fl_chart のチャートは CustomPainter で描画するため、テキスト検索では検出できない。`tester.widget<PieChart/BarChart>(find.byType(...)).data` でチャートデータを直接検証する。BarChart の場合は `barGroups[i].barRods[0].toY` で棒の高さ、`.rodStackItems` でスタック構成を検証する。`extraLinesData.horizontalLines` で目標ライン等の補助線も検証可能。
- **具体例**: `activity_pie_chart_test.dart` - sections を直接アサート; `weekly_stacked_bar_chart_test.dart` - barGroups, rodStackItems, toY を直接アサート; `weekly_stacked_bar_chart_goal_line_test.dart` - horizontalLines の y, color, dashArray, label を検証
- **スキル化済み**: Yes

## FutureProvider.autoDispose + ViewModel 経由の目標達成度パターン
- **カテゴリ**: 設計
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: Service 不要のケースでは FutureProvider.autoDispose で Repository 単一メソッド + 純粋関数計算（CalculationService）を組み合わせる。稼働中のセッションエントリ（endedAt == null）も考慮するため、timerState.entries との重複排除が必要。アーカイブ済みエンティティの名前解決にも使える（getAllActivities を参照）。
- **具体例**: `dailyGoalProgressProvider` - LogRepository.getEntriesForDate + CalculationService.calculateWorkDuration + timerState.entries の重複排除; `allActivitiesProvider` - ActivityRepository.getAllActivities で全アクティビティ取得（アーカイブ含む）
- **スキル化済み**: No

## CustomPaint の find.byType テストでの多重マッチ問題
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `find.byType(CustomPaint)` は Scaffold 等のフレームワーク Widget にも含まれるため複数マッチする。`find.descendant(of: find.byType(TargetWidget), matching: find.byType(CustomPaint))` でスコープを限定する必要がある。
- **具体例**: `progress_ring_test.dart` - ProgressRing 内の CustomPaint のみを検証するため descendant を使用
- **スキル化済み**: No

## DB シーディング追加時の既存テスト影響
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: DB の onCreate でシーディング（初期データ投入）を追加すると、`NativeDatabase.memory()` を使う全テストの初期状態が変わる。件数アサーション（isEmpty, hasLength(N)）、`.first` 参照による取得、名前重複の3種類の修正が必要。修正パターン: (1) hasLength → hasLength(default + N), (2) all.first → all.firstWhere((a) => a.id == id), (3) シードと衝突する名前を変更。
- **具体例**: `_seedDefaultActivities()` で9件投入 → `drift_activity_repository_test.dart`, `app_database_test.dart`, `tracking_service_impl_test.dart`, `timer_view_model_test.dart`, `timer_page_test.dart` の19テストが影響
- **スキル化済み**: No

## 機能削除時のテスト整理パターン
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: UI 機能を削除する際、ソースコードの削除だけでなくテストの3段階整理が必要: (1) 削除対象テストの削除（機能そのもののテスト）、(2) 変更対象テストの更新（削除した機能を参照するテスト）、(3) 新しい振る舞いのテスト追加（削除後の状態を検証）。特に state クラスからフィールドを削除する場合、コンパイルエラーが多数のテストに波及する。
- **具体例**: STORY-015 selectedActivity 削除 - timer_state_test (4テスト削除), timer_view_model_test (7テスト削除 + SharedPreferences setup 削除), timer_page_test (11テスト削除/変更), goal_progress テスト群の全面更新
- **スキル化済み**: No

## ViewModel エラーメッセージ二重ラップ防止
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: ViewModel で `StateError('操作エラー: $domainError')` のようにラップし、Page 側の catch でも `'操作エラー: $e'` を付与すると、「操作エラー: Bad state: 操作エラー: ...」のような冗長メッセージになる。修正: ViewModel はドメインエラーをそのまま throw し、Page 側で `_errorMessage(operation, error)` ヘルパーで統一的にメッセージ付与する。
- **具体例**: `TimerNotifier.startWork` の Failure ケースで `throw error` に変更、`timer_page.dart` に `_errorMessage()` ヘルパー追加
- **スキル化済み**: No

## Failure 時のアクティブデータリフレッシュ
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: QuickStartGrid 等でキャッシュ済みデータを表示中にバックグラウンドでデータが変更された場合（アーカイブ等）、操作失敗時に `_refreshActiveActivitiesFlag()` を呼んでキャッシュを最新化する。stale-state-guard パターンの Layer 2 防御に該当。
- **具体例**: `TimerNotifier.startWork` の Failure ケースで `await _refreshActiveActivitiesFlag()` を追加
- **スキル化済み**: No

## UI フォールバック値パターン（activeActivities 検索）
- **カテゴリ**: バグ防止
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: activeActivities 一覧から activityId でエンティティを検索して属性（色、名前等）を解決する場合、アーカイブ済み等で見つからないケースではフォールバック値を返す。色の場合は defaultColorValue、名前の場合はステータスラベルのみ（アクティビティ名なし）。null を返すと UI 表示が欠けたり、不整合が生じる。
- **具体例**: (1) `_TimerPageState._resolveActivityColor` で match.isEmpty の場合 `Color(ActivityData.defaultColorValue)` を返す; (2) STORY-034 `TimerNotifier._findActivityName` で見つからない場合 null を返し、`_buildPayload` でステータスラベルのみにフォールバック
- **スキル化済み**: No

## FOUC 防止: Future.wait で並列取得 + 1回の state 更新
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Notifier の初期化/復元処理で複数の非同期データ取得を逐次実行すると、各 await 後に state を更新するため中間状態が一瞬描画される（FOUC）。`Future.wait` で並列取得し、結果を1回の `state =` でまとめて反映することで解消する。テストは `container.listen` で state 変更回数をカウントして1回のみであることを検証する。
- **具体例**: `TimerNotifier.restoreState()` - `restoreSession()` + `getActiveActivities()` を `Future.wait` で並列取得、stopped/非 stopped の分岐で1回だけ state 更新
- **スキル化済み**: No

## Riverpod 3 の StateProvider 廃止
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Riverpod 3.x では StateProvider が廃止されている。代わりに NotifierProvider を使い、Notifier クラスに state 変更メソッドを定義する。同様に valueOrNull も廃止されており、value で代替する。
- **具体例**: `selectedActivityProvider` を `NotifierProvider<SelectedActivityNotifier, ActivityData?>` で定義。`select(ActivityData?)` メソッドで state を変更。
- **スキル化済み**: No

## DropdownButton の等価性問題: id ベース比較
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: DropdownButton の value にカスタムクラスのインスタンスを使用すると、異なるインスタンスでも同じ論理値を指す場合に value の一致判定が失敗する（== / hashCode 未定義の場合）。回避策として、DropdownButton<int?> で id を value にし、onChanged で id からインスタンスを逆引きする。
- **具体例**: `_ActivityFilterDropdown` で `DropdownButton<int?>` を使用、value は `selectedActivity?.id`、onChanged で `activeActivities.firstWhere((a) => a.id == activityId)` で逆引き
- **スキル化済み**: No

## 外部サービス連携の try-catch 握りつぶしパターン
- **カテゴリ**: エラーハンドリング
- **遭遇回数**: 3
- **発見元**: time-tracker
- **概要**: ビジネスロジック成功後に呼び出す外部サービス（通知、アナリティクス等）は、失敗してもアプリの主要機能に影響させない。try-catch で例外を握りつぶし debugPrint でログ出力する。テストでは Mock に thenThrow を設定して、例外伝播しないことを verify する。権限リクエスト等の前処理も同じ try-catch ブロック内に置くことで、権限拒否時も握りつぶされる。
- **具体例**: `TimerNotifier._notifyStart/Update/Stop` で NotificationService の例外を catch。テスト: `timer_notification_test.dart` の「通知失敗がアプリ動作に影響しない」グループ。STORY-020: `requestNotificationPermission` を `_notifyStart` の try-catch 内に追加。
- **スキル化済み**: No

## Platform 分岐の DI パターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: プラットフォーム固有の Infrastructure 実装を DI で切り替える場合、`dart:io` の `Platform.isAndroid` 等を providers.dart 内で判定し、domain interface 型の Provider で返す。テスト時は NoOp 実装がデフォルトで注入されるため、既存テストは変更不要。
- **具体例**: `notificationServiceProvider` - Android: `ForegroundTaskNotificationService`, その他: `NoopNotificationService`
- **スキル化済み**: No

## Drift storeDateTimeAsText と customSelect の組み合わせ
- **カテゴリ**: バグ防止
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: `storeDateTimeAsText: true` の場合、customSelect で日時比較するとき ISO 8601 文字列で比較し、秒差計算には `strftime('%s', col)` を使う。また、`row.read<String>('date_column')` で取得した文字列を `DateTime.parse()` するとUTCとして解析される場合があるため、`.toLocal()` + `DateTime(y,m,d)` で論理日付に変換する必要がある。
- **具体例**: `DriftMonthlyReportRepository.getActivityBreakdown` - Variable.withString, strftime 使用; `getWeeklyBreakdown` - DateTime.parse(dateStr).toLocal() で UTC→ローカル変換
- **スキル化済み**: Yes

## Widget テストで find.text が複数 Widget にマッチする問題
- **カテゴリ**: テスト
- **遭遇回数**: 4
- **発見元**: time-tracker, shisoku-flutter
- **概要**: `find.text('X')` が対象 Widget 以外の別 Widget にもマッチして `findsOneWidget` が失敗する。対処法: (1) `find.descendant(of: find.byType(TargetWidget), matching: find.text('X'))` でスコープを限定する、(2) `findsAtLeast(1)` に変更する（テキストの存在確認だけで十分な場合）。
- **具体例**: (1) `timer_page_test.dart` - EntryTile の「稼働」テキストが DurationSummaryRow にも存在; (2) `day_detail_page_test.dart` - 「休憩」テキストが両方に存在; (3) `end_page_test.dart` - EndPage タイトル「結果」と ResultTable ヘッダー「結果」列が重複。`findsAtLeast(1)` で対処。
- **スキル化済み**: Yes

## Service 層での入力 ID 存在チェック
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Service 層でリスト内の対象 ID を検索する際、ID が見つからないケースのガードを忘れがち。`for` ループで `found` フラグを管理し、未発見時は `EntryNotFoundError` 等のドメインエラーを返す。Gemini レビューで検出されやすい。
- **具体例**: `LogServiceImpl.updateRunningEntryStartTime` - entries リストから entryId を探す際、`bool found = false` + `if (!found) return Result.failure(const EntryNotFoundError())`
- **スキル化済み**: No

## UI エラーメッセージの重複排除
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: 同じドメインエラーを処理する Page が複数ある場合（timer_page, day_detail_page 等）、`switch (error)` によるエラーメッセージ生成ロジックが重複する。LogError の拡張メソッドや共通ヘルパーとして切り出すことで DRY にできる。Gemini レビューで Low 指摘される。
- **具体例**: `timer_page.dart` と `day_detail_page.dart` の `StartTimeEditResult` 処理で `FutureStartTimeError` / `OverlappingEntryError` のメッセージ分岐が重複
- **スキル化済み**: No

## Interface メソッド追加時の Mock スタブ漏れ
- **カテゴリ**: テスト
- **遭遇回数**: 4
- **発見元**: time-tracker, shisoku-flutter
- **概要**: domain interface にメソッドを追加した場合、mocktail の Mock クラスは未スタブのメソッドに対して null を返す。`Future<bool>` を返すメソッドでスタブが未設定だと `type 'Null' is not a subtype of type 'Future<bool>'` エラーになる。テストの setUp で全 Mock メソッドにデフォルトスタブを設定しておくことが重要。新たに `Duration` 型を使うメソッドを追加する場合は `registerFallbackValue(Duration.zero)` + `registerFallbackValue(DateTime(...))` も必要。
- **具体例**: (1) STORY-020 `NotificationService.requestNotificationPermission()` 追加時、既存テスト6件が失敗。setUp にスタブ追加で解決。(2) STORY-033 `sendTimerData()` 追加時、`registerFallbackValue` 未設定で7テスト失敗。`setUpAll` に `registerFallbackValue(Duration.zero)` + `registerFallbackValue(DateTime(...))` 追加で解決。(3) STORY-008 `RankingRepository` Provider 追加時、EndPage を描画する全テスト（end_page_test, game_page_test, widget_test）で `rankingRepositoryProvider.overrideWithValue(mockRankingRepository)` が必要。
- **スキル化済み**: Yes

## Dart while 文での case パターンマッチング非対応
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: Dart 3.x では `if-case` 構文は使えるが、`while (_current case SomeType(value: final v) when ...)` のような while-case 構文はコンパイルエラーになる。ヘルパーメソッドで演算子マッチングを行い、while ループの条件式を通常の null チェックにする必要がある。
- **具体例**: `ExpressionEvaluator` の再帰下降パーサーで `_matchOperator(Set<String>)` ヘルパーを導入し、`while ((op = _matchOperator(ops)) != null)` に書き換え
- **スキル化済み**: No

## 純粋計算クラスの domain 層配置パターン
- **カテゴリ**: 設計
- **遭遇回数**: 2
- **発見元**: time-tracker, shisoku-flutter
- **概要**: dart:core のみ依存する純粋計算ロジックは static メソッドのみの class として domain 層に配置する。private コンストラクタでインスタンス化を防止。外部パッケージ・Flutter 依存なしの制約を満たす。
- **具体例**: time-tracker: `CalculationService` (static メソッド集), shisoku-flutter: `ExpressionEvaluator` (再帰下降パーサー)
- **スキル化済み**: No

## SharedPreferences 関数注入によるローカルストレージ Repository テスト可能パターン
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: SharedPreferences への直接依存を避けるため、`StringLoader` (`Future<String?> Function(String key)`) と `StringSaver` (`Future<bool> Function(String key, String value)`) の typedef を定義し、コンストラクタ注入する。テスト時は `Map<String, String>` をバッキングストアとして使用し、実行時は `SharedPreferences.getString` / `setString` を注入する。AssetProblemRepository の `JsonLoader` 関数注入パターンのローカルストレージ版。
- **具体例**: `LocalRankingRepository(loadString: (key) async => storage[key], saveString: (key, value) async { storage[key] = value; return true; })` - テスト時は `Map<String, String> storage = {}` を使用
- **スキル化済み**: No

## JsonLoader 関数注入による Asset テスト可能パターン
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: rootBundle.loadString 等のアセット読み込みをテストする際、typedef で関数型を定義しコンストラクタ注入する。テスト時はインメモリ JSON 文字列を返す関数を注入し、Random もシード固定で注入することで決定的テストが可能。
- **具体例**: `AssetProblemRepository(loadJson: (_) async => testJson, random: Random(42))` - JsonLoader typedef + テスト用 `_loaderReturning()` / `_loaderThrowing()` ヘルパー
- **スキル化済み**: No

## TaskHandler Isolate へのデータ送信時の二重計算防止
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Main isolate から TaskHandler（別 isolate）にタイマーデータを送信する際、「累積時間」として total（完了済み + 進行中）を渡すと、TaskHandler 側で進行中分を再度加算して二重計算になる。累積時間は「完了済みエントリのみの合計」を渡し、TaskHandler 側で `累積 + (now - currentEntryStartedAt)` として合算するのが正しい。
- **具体例**: STORY-033 `_notifyStart`/`_notifyUpdate` で `CalculationService.calculateWorkDuration(entries, now: now)` (total) ではなく `calculateWorkDuration(entries)` (completedのみ) を `sendTimerData.accumulatedWorkDuration` に渡す。Gemini レビューで Critical 指摘として検出。
- **スキル化済み**: No

## atom ウィジェットの Riverpod 非依存テストパターン
- **カテゴリ**: テスト
- **遭遇回数**: 2
- **発見元**: shisoku-flutter
- **概要**: Riverpod 非依存の pure widget（atom）は ProviderScope なしで `MaterialApp(home: Scaffold(body: Widget(...)))` でラップしてテストする。コールバック検証には変数キャプチャ（`Difficulty? selectedValue; onSelect: (d) { selectedValue = d; }`）を使用。選択状態の検証は `find.ancestor(of: find.text(label), matching: find.byType(FilledButton/OutlinedButton))` で対象ボタンの型を確認する。
- **具体例**: `rules_display_test.dart` - `MaterialApp(home: Scaffold(body: SingleChildScrollView(child: RulesDisplay())))` でラップ; `difficulty_selector_test.dart` - `buildSubject(selectedDifficulty:, onSelect:)` ヘルパーで状態とコールバックを注入
- **スキル化済み**: Yes

## FakeAsync 内での ProviderContainer ライフサイクル
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: FakeAsync().run() 内で ProviderContainer を生成する場合、addTearDown は FakeAsync のスコープ外なので使えない。FakeAsync コールバック末尾で手動 dispose する。また setUp/tearDown で container を管理する通常パターンは FakeAsync と相性が悪いため、テストごとにインラインで container を生成・破棄するか、ヘルパー関数で共通化する。
- **具体例**: `timer_notifier_test.dart` の `runTimerTest` ヘルパー: FakeAsync().run 内で container 生成 → body 実行 → stop + dispose

## GamePage 統合テストでの状態遷移ヘルパーパターン
- **カテゴリ**: テスト
- **遭遇回数**: 2
- **発見元**: shisoku-flutter
- **概要**: ConsumerStatefulWidget のページテストで、テスト対象ページに到達するために複数のフェーズ遷移が必要な場合、`ProviderScope.containerOf(tester.element(...))` で container を取得し、Notifier のメソッドを直接呼んで遷移させるヘルパーを作成する。UI 操作（tap）+ Notifier 直接呼び出しの組み合わせで、テスト対象ページの前提状態を効率的にセットアップできる。
- **具体例**: `game_page_test.dart` の `navigateToPlaying()` - tester.tap('スタート') で idle->countdown 遷移 + container.read(notifier).completeCountdown() で countdown->playing 遷移
- **スキル化済み**: No

## ConsumerStatefulWidget でのローカル State + Value Object パターン
- **カテゴリ**: 設計
- **遭遇回数**: 2
- **発見元**: shisoku-flutter
- **概要**: 1問ごとにリセットされる一時的な入力状態は Notifier ではなく ConsumerStatefulWidget のローカル State で管理する。生のコレクション型（List<Token>等）ではなく、Value Object（Expression）でラップしバリデーションを型レベルで保証する。Widget は setState() と Value Object のメソッド呼び出しのみを行う。これにより Notifier はゲーム進行状態のみに集中でき、バリデーション漏れが構造的に防止される。
- **具体例**: `GamePage._expression` (Expression) をローカル State で管理、`expression.addNumber/addOperator/...` でバリデーション内蔵の操作、`GameSessionNotifier` はゲーム進行（skipQuestion, submitAnswer）のみ担当。以前は `List<Token>` + `ExpressionInputValidator` (static class) だったが、ADR-001 で Value Object に統合。
- **スキル化済み**: No

## 【設計原則】Always-Valid Domain Model: バリデーション済みデータのドメインオブジェクト昇格
- **カテゴリ**: 設計原則
- **遭遇回数**: 2
- **発見元**: shisoku-flutter (ADR-001)
- **概要**: domain 層にバリデーションロジックがある場合、バリデーション済みの結果をドメインオブジェクト（Value Object や Entity）に昇格させる。static Validator + 生のコレクション型（List, Map 等）の組み合わせは Primitive Obsession のシグナル。ドメインオブジェクトはファクトリメソッド（addXxx, create, from 等）経由でのみインスタンスを生成し、不正な状態を構造的に不可能にする（Always-Valid Domain Model）。Value Object はこの原則の代表的な実現手段。
- **判断基準（Architect 向け）**:
  - domain 層に static Validator + 生のコレクション/プリミティブ型がペアで存在する → VO 昇格を検討
  - UI 層が Validator を呼び忘れると不正状態が生まれる設計 → VO で防止必須
  - interface 化は「実装差し替えが必要か」で判断（純粋計算ロジックは interface 不要）
- **実装基準（Developer 向け）**:
  - VO は `final class` + `const` コンストラクタ + immutable
  - ファクトリメソッド（addXxx）は `VO?` を返す（エラー種別不要なら Result 型は過剰）
  - `canAddXxx` クエリメソッドも用意（UI のボタン有効/無効の事前判定用）
  - テスト移行は既存 Validator テストケースを VO の API に1対1で移行
- **具体例**: `ExpressionInputValidator` (static) + `List<Token>` → `Expression` (Value Object)。ADR-001 に基づく。
- **参考**: Martin Fowler: Value Object, Enterprise Craftsmanship: Always-Valid Domain Model
- **スキル化済み**: No

## Timer ベースの遅延進行 + 入力ロックパターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: 正答メッセージを一定時間表示してから自動進行する場合、(1) setState で入力ロック + メッセージ表示、(2) Timer で遅延後に Notifier.advance() + setState でリセット、(3) dispose で Timer キャンセル、(4) Timer コールバック内で mounted チェック。UI 側のローカル State で管理し、Notifier には「結果記録」と「次問題遷移」を分離したメソッドを用意する。テストでは `tester.pump(Duration)` で Timer を進める。
- **具体例**: `GamePage._onCorrectAnswer` - `_isInputLocked = true` + `Timer(2000ms)` → `advanceToNextQuestion()` + ロック解除。Notifier の `submitAnswer` は結果記録のみ、`advanceToNextQuestion` は遷移のみ。
- **スキル化済み**: No

## 文字列比較による条件分岐を enum に置換するパターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: UI で `_judgmentMessage == '正解!'` のような文字列比較で色やスタイルを分岐している場合、domain の enum 型（AnswerResult 等）を State に保持し、getter で switch 分岐する方が型安全。enum が既に存在するなら String を保持する理由はない。
- **具体例**: `GamePage._lastAnswerResult: AnswerResult?` + `_judgmentMessageText` / `_judgmentMessageColor` getter。リファクタリングで `_judgmentMessage: String?` から置換。
- **スキル化済み**: No

## Value Object テスト用ヘルパー関数の意図的重複パターン
- **カテゴリ**: テスト
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: Value Object の `create()` ファクトリが `Result` を返す場合、テスト内で `(VO.create('x') as Success<VO, Error>).value` の展開コードが冗長になる。`_voName(String raw)` のようなファイルスコープのヘルパー関数で簡潔化する。テストファイル間の依存を避けるため、各テストファイルに同じヘルパーを定義するのは意図的な重複（テスト独立性を優先）。共通テストユーティリティに切り出すと import 管理が複雑化し、テストの自己完結性が損なわれる。
- **具体例**: `_rankingName(String raw)` が `ranking_name_test.dart`, `local_ranking_repository_test.dart`, `ranking_page_test.dart` の3ファイルに同一定義。
- **スキル化済み**: No

## Static Validator から Value Object へのリファクタリングパターン
- **カテゴリ**: 設計
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: Static メソッドのみの Validator クラスと生のコレクション型の組み合わせを、Always-Valid な Value Object に統合するリファクタリング。手順: (1) Value Object のテストを先に書く（既存テストケースを API に移行）、(2) Value Object を実装（Validator のロジックを移動）、(3) UI の参照を切り替え、(4) 旧 Validator ファイルと旧テストを削除、(5) 全テスト PASS を確認。canAddXxx クエリメソッドは UI のボタン有効/無効判定用に残す。addXxx は null を返す設計（Result 型は不要）。
- **具体例**: `ExpressionInputValidator` (static class) + `List<Token>` → `Expression` (final class, Value Object)。ADR-001 に基づく。
- **スキル化済み**: No
