# 実例: selectedProject の stale reference バグ

## 背景

タイマー画面で「前回使用したプロジェクト」を SharedPreferences に記憶し、次回起動時に自動選択する機能を実装。
しかし、プロジェクトをアーカイブした後もキャッシュが残り、アーカイブ済みプロジェクトでタイマーを開始できてしまった。

## 発見されたバグ

### Bug 1: ViewModel の loadLastProject で state クリア漏れ

```dart
// NG: SharedPreferences はクリアしたが state.selectedProject が残る
} else {
  _prefs.remove(_lastUsedProjectKey);
}

// OK: 両方クリア
} else {
  state = state.copyWith(clearSelectedProject: true);
  _prefs.remove(_lastUsedProjectKey);
}
```

### Bug 2: startWork でアーカイブ済みチェックなし

```dart
// NG: Repository がアーカイブ済みをチェックしない → 開始できてしまう

// OK: Layer 1 — Repository のトランザクション内でチェック
// error.dart
final class ProjectNotActiveError extends TrackingError {
  const ProjectNotActiveError();
}

// drift_tracking_repository.dart startWork 内
final project = await (_db.select(_db.projects)
  ..where((t) => t.id.equals(projectId))).getSingleOrNull();
if (project == null || project.isArchived) {
  return const Result.failure(ProjectNotActiveError());
}
```

### Bug 2 続き: ViewModel での Layer 1 エラーハンドリング

```dart
// OK: Layer 2 — throw せず状態遷移で処理
case Failure(error: ProjectNotActiveError()):
  state = state.copyWith(clearSelectedProject: true);
  _prefs.remove(_lastUsedProjectKey);
```

## 教訓

1. **キャッシュの書き込みと読み込みは非対称** — 書き込み時に有効でも読み込み時に無効になりうる
2. **state と永続化ストアは両方クリアする** — 片方だけでは不整合が残る
3. **ビジネスルールは Repository 層で強制する** — UI/ViewModel での検証は「ベストエフォート」、Repository が「ラストライン」
