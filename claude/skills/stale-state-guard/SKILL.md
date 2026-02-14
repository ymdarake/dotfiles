---
name: stale-state-guard
description: |
  Flutter Layer-first DDDプロジェクトで、キャッシュされたドメインエンティティ参照（SharedPreferences、UI state等）が
  stale（陳腐化）するバグを防ぐ3層防御パターン。

  **自動発動条件（flutter-developer / flutter-plan から参照）:**
  - SharedPreferences や UI state にドメインエンティティのID/参照を保存する実装時
  - キャッシュされたエンティティを使って操作を実行する実装時
  - 「選択中の○○」「前回使用した○○」「お気に入りの○○」等の記憶機能の実装時

  **手動発動条件:**
  - `/stale-state-guard` で直接呼び出し
  - 「stale state対策して」「キャッシュ整合性チェック」等
---

# Stale State Guard パターン

UI state や SharedPreferences にドメインエンティティの参照（ID等）をキャッシュした場合、
エンティティが後からアーカイブ/削除/無効化されると **stale reference** になる。
このパターンは3層で防御する。

## アンチパターン

```dart
// NG: キャッシュから取得した ID をそのまま信用して操作実行
final cachedProjectId = prefs.getInt('last_project_id');
if (cachedProjectId != null) {
  await service.startWork(projectId: cachedProjectId); // アーカイブ済みかもしれない!
}
```

## 3層防御パターン

### Layer 1: Repository層 — ビジネスルールの強制

操作実行時にエンティティの有効性を**トランザクション内で**検証する。
どの経路から呼ばれても必ずチェックされるラストライン防御。

- sealed class のエラー型に専用エラーを追加（例: `ProjectNotActiveError`）
- Repository の操作メソッド内でアクティブ/存在チェック
- TOCTOU問題排除のためトランザクション内でチェック

### Layer 2: ViewModel層 — キャッシュロード時の検証

キャッシュからエンティティ参照を復元する際に**現在も有効か確認**する。

- ロード時: ID → アクティブ一覧と照合 → 見つからなければキャッシュクリア + state クリア
- 操作失敗時: Layer 1 エラーをハンドリング → state クリア（throw せず状態遷移で処理）
- `copyWith` に明示的クリア機構（`clearXxx: true` パラメータ）

### Layer 3: UI層 — フォールバック

操作失敗時のユーザーフィードバックとフォールバックUI。

- ViewModel の state 変化を検知してフォールバック動作（例: ダイアログ再表示）

## チェックリスト

エンティティ参照をキャッシュする機能の実装時に確認:

- [ ] Repository の操作メソッドにエンティティ有効性チェックがあるか
- [ ] sealed class エラー型に専用エラーが定義されているか
- [ ] ViewModel のキャッシュロードで無効エンティティをクリアしているか
- [ ] ViewModel で Layer 1 エラー時に state をクリアしているか（throw ではなく状態遷移）
- [ ] UI にフォールバック動作があるか

## 実例

今回のプロジェクトでの適用例: [references/example-fix.md](references/example-fix.md)
