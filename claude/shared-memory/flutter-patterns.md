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
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: ダイアログが複数種類のアクション結果を返す場合、sealed class で型安全に分岐する。
- **具体例**: `_EditDialogResult` → `_TimeEditResult` / `_MoveDateResult` in `day_detail_page.dart`
- **スキル化済み**: No

## 未来日付バリデーションの二重防御
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: UI 側で DatePicker の lastDate 制限 + Service 層で FutureDateError バリデーション。UI をバイパスする経路に備えた防御的プログラミング。
- **具体例**: `LogServiceImpl.moveEntryToDate` の未来日チェック + `_EntryEditDialog._pickDate` の lastDate: today
- **スキル化済み**: No

## invalidateSelf vs 直接 state 更新の判断
- **カテゴリ**: バグ防止
- **遭遇回数**: 1
- **発見元**: time-tracker
- **概要**: Notifier の操作が「別のデータソースに影響する」場合は invalidateSelf() で再フェッチ、「同じデータソース内の変更」なら直接更新。Gemini レビューで発見されたバグ。
- **具体例**: `DayDetailNotifier.moveEntryToDate` - 移動先 entries で state 更新 → 移動元画面と不整合 → invalidateSelf() に修正
- **スキル化済み**: No
