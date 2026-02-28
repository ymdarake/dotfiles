# Maestro E2E 横断パターン記録

## Semantics ネストで子要素の identifier が検出不可
- **カテゴリ**: Semantics
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `Semantics(identifier:)` が入れ子になると、Maestro の `id` セレクタが子要素の identifier を検出できない場合がある。親 `Semantics` がアクセシビリティツリーのノードを合成し、子の identifier が隠れる。
- **具体例**: `WeeklyStackedBarChart` — 外側 `maestro_log_weekly_chart` + 内側 `maestro_log_week_prev` → prev が検出不可。外側 Semantics を削除してフラットにするか、tooltip ベースのタップに変更して解決。
- **スキル化済み**: No

## IndexedStack + FutureProvider.autoDispose のキャッシュ不整合
- **カテゴリ**: 非同期待機
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: IndexedStack は全ページを Widget ツリーに保持するため、FutureProvider.autoDispose が最初の空データをキャッシュしたまま更新されない。タイマーでデータを作成しても、ログページのプロバイダが invalidate されないと古い空データが表示される。
- **具体例**: `activityBreakdownProvider` / `weeklyBreakdownProvider` がタイマー停止後に invalidate されず、ログページで「データなし」表示。`_invalidateLogProviders()` に追加して解決。
- **スキル化済み**: No

## scrollUntilVisible で非同期ロード中のウィジェットが検出不可
- **カテゴリ**: スクロール
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `scrollUntilVisible` は物理スクロールのみ行い、非同期データのロード完了を待たない。`FutureProvider.autoDispose` の `when` で `loading` 状態のとき `CircularProgressIndicator` が表示され、対象の Semantics ウィジェットがツリーに存在しない。
- **具体例**: `maestro_log_pie_chart` — `breakdownAsync.when` の loading 中は pie chart が未描画。`extendedWaitUntil` を併用するか、外側のラッパーを scroll 対象にして内部は `extendedWaitUntil` で待機。
- **スキル化済み**: No

## tooltip ベースのタップは Semantics より安定
- **カテゴリ**: Flow設計
- **遭遇回数**: 2
- **発見元**: time-tracker
- **概要**: `IconButton` や `PopupMenuButton` に `tooltip` を設定すると、Maestro の `tapOn: "tooltip text"` で確実にタップできる。`Semantics(identifier:)` は入れ子やウィジェットの種類によって検出できない場合があるが、tooltip はアクセシビリティツリーに直接 label として登録されるため安定。リスト内の同一ウィジェットを個別に特定する場合、動的な tooltip (例: `'${name} menu'`) で区別できる。
- **具体例**: (1) `WeeklyStackedBarChart` の前週/次週ボタン — `Semantics(identifier:)` → `tooltip` + `tapOn` に変更。(2) 設定画面の `PopupMenuButton` — デフォルト tooltip "Show menu" を `'${activity.name} menu'` に変更し、9件のアクティビティを個別にアーカイブ可能に。
- **スキル化済み**: No

## UI テキスト変更に伴う assertVisible の一括修正漏れ
- **カテゴリ**: Flow設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: AppBar タイトルやラベルなどの静的テキストを変更した際、`assertVisible: "旧テキスト"` で画面遷移を確認しているフローが複数箇所で壊れる。テキストベースのアサーションは変更に脆い。Semantics identifier ベースのアサーションを優先すべき。
- **具体例**: STORY-017 でログ画面の AppBar タイトル「ログ」をドロップダウン（デフォルト「すべて」）に変更。6フロー9箇所の `assertVisible: "ログ"` が失敗。`grep` で全フローを横断検索して一括修正。
- **スキル化済み**: No

## 停止中は _resolveActivityName が null を返すためテスト状態に注意
- **カテゴリ**: Flow設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `_resolveActivityName(timerState)` は `status == TimerStatus.stopped` のとき `null` を返す。停止後のエントリ一覧では EntryTile の title が「稼働」にフォールバックする。アクティビティ名表示のテストは稼働中または休憩中に行う必要がある。
- **具体例**: STORY-022 のアクティビティ名表示テスト。休憩中 (currentActivityId が維持されている状態) でエントリの title に "E2ETest" が表示されることを確認。停止後にテストすると「稼働」になり失敗する。
- **スキル化済み**: No

## スワイプ操作は座標ベースのパーセンテージ指定が安定
- **カテゴリ**: Flow設計
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Maestro の `swipe` コマンドでリスト行をスワイプする場合、Semantics identifier がない要素にはパーセンテージ座標指定 (`start: 80%, 85%` / `end: 20%, 85%`) が安定。`from` + `direction` 指定よりも確実。既存のフロー (notification_action_buttons) でも同様の手法を使用。
- **具体例**: STORY-024 のスワイプ削除テスト。EntryTile の ListTile に identifier がないため、画面下部 (85%) の位置で左スワイプを実行して Dismissible の確認ダイアログを発火。
- **スキル化済み**: No

## Maestro フロー名にスラッシュやコロンを含めるとレポート生成が失敗する
- **カテゴリ**: Flow設計
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: Maestro の `name` フィールドにスラッシュ (`/`) やコロン (`:`) を含めると、テスト結果のHTMLレポート生成時にファイルパスとして不正な文字が含まれ `FileNotFoundException` が発生する。テスト自体は PASS してもコマンドの exit code が 1 になる。
- **具体例**: `name: "STORY-017/023: Submit Button..."` でレポートパスが `/tests/2026-02-28/ai-report-STORY-017/023: ...` となり失敗。ハイフン区切り `name: "STORY-017-023 Submit Button..."` に変更して解決。
- **スキル化済み**: No

## i18n 導入後のエミュレータロケール設定漏れ
- **カテゴリ**: デバッグ
- **遭遇回数**: 1
- **発見元**: shisoku-flutter
- **概要**: Flutter の i18n (AppLocalizations) 導入後、エミュレータのロケールが `en-US` のままだと、テストフロー内の日本語 `assertVisible` が全て失敗する。表示される文字列の「出所」が変わった（ハードコード → ARB ファイル）だけで値は同じはずだが、エミュレータのロケールに応じてどの ARB が使われるかが決まる。
- **具体例**: shisoku_flutter の全5フローが `"算数パズルゲーム" is visible` で失敗。`adb root` → `setprop persist.sys.locale ja-JP` → `settings put system system_locales ja-JP` → `stop; start` でロケール変更して解決。
- **スキル化済み**: No

## FAB とリスト末尾アイテムの重なり問題
- **カテゴリ**: スクロール
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `Scaffold` の `floatingActionButton` は `ListView` の上にオーバーレイされる。リストの末尾アイテムが画面下部に表示されると、FAB がタップ対象と重なり、Maestro が意図しない要素をタップする。`tapOn` は COMPLETED と報告されるが、実際には FAB が受け取ってしまう。
- **具体例**: 設定画面の9番目のアクティビティ「食事」の PopupMenuButton と FAB が重なり、FAB がタップされて「アクティビティ追加」ダイアログが開いてしまう。ListView に `padding: EdgeInsets.only(bottom: 80)` を追加して解決。
- **スキル化済み**: No
