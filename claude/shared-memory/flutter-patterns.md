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
- **遭遇回数**: 2
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

## UI フォールバック色パターン
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: activeActivities 一覧からアクティビティを検索して色を解決する場合、アーカイブ済み等で見つからないケースでは null ではなくフォールバック色（defaultColorValue）を返す。null を返すと色が完全に消えてユーザーに視覚的な欠けが生じる。
- **具体例**: `_TimerPageState._resolveActivityColor` で match.isEmpty の場合 `Color(ActivityData.defaultColorValue)` を返す
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
- **遭遇回数**: 3
- **発見元**: time-tracker
- **概要**: `find.text('X')` が対象 Widget 以外の別 Widget（DurationSummaryRow の「稼働」/「休憩」ラベル等）にもマッチして `findsOneWidget` が失敗する。`find.descendant(of: find.byType(TargetWidget), matching: find.text('X'))` でスコープを限定する。CustomPaint の多重マッチと同じ原理。
- **具体例**: `timer_page_test.dart` - EntryTile の「稼働」テキストが DurationSummaryRow にも存在; `day_detail_page_test.dart` - 「休憩」テキストが DurationSummaryRow と EntryTile の両方に存在。find.descendant(of: find.byType(EntryTimeline)) でスコープ限定して解決。
- **スキル化済み**: No

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
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: domain interface にメソッドを追加した場合、mocktail の Mock クラスは未スタブのメソッドに対して null を返す。`Future<bool>` を返すメソッドでスタブが未設定だと `type 'Null' is not a subtype of type 'Future<bool>'` エラーになる。テストの setUp で全 Mock メソッドにデフォルトスタブを設定しておくことが重要。新たに `Duration` 型を使うメソッドを追加する場合は `registerFallbackValue(Duration.zero)` + `registerFallbackValue(DateTime(...))` も必要。
- **具体例**: (1) STORY-020 `NotificationService.requestNotificationPermission()` 追加時、既存テスト6件が失敗。setUp にスタブ追加で解決。(2) STORY-033 `sendTimerData()` 追加時、`registerFallbackValue` 未設定で7テスト失敗。`setUpAll` に `registerFallbackValue(Duration.zero)` + `registerFallbackValue(DateTime(...))` 追加で解決。
- **スキル化済み**: No

## TaskHandler Isolate へのデータ送信時の二重計算防止
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Main isolate から TaskHandler（別 isolate）にタイマーデータを送信する際、「累積時間」として total（完了済み + 進行中）を渡すと、TaskHandler 側で進行中分を再度加算して二重計算になる。累積時間は「完了済みエントリのみの合計」を渡し、TaskHandler 側で `累積 + (now - currentEntryStartedAt)` として合算するのが正しい。
- **具体例**: STORY-033 `_notifyStart`/`_notifyUpdate` で `CalculationService.calculateWorkDuration(entries, now: now)` (total) ではなく `calculateWorkDuration(entries)` (completedのみ) を `sendTimerData.accumulatedWorkDuration` に渡す。Gemini レビューで Critical 指摘として検出。
- **スキル化済み**: No
