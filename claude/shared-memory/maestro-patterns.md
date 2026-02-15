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
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: `IconButton` に `tooltip` を設定すると、Maestro の `tapOn: "tooltip text"` で確実にタップできる。`Semantics(identifier:)` は入れ子やウィジェットの種類によって検出できない場合があるが、tooltip はアクセシビリティツリーに直接 label として登録されるため安定。
- **具体例**: `WeeklyStackedBarChart` の前週/次週ボタン — `Semantics(identifier: 'maestro_log_week_prev')` → `IconButton(tooltip: '前週')` + `tapOn: "前週"` に変更して解決。
- **スキル化済み**: No
