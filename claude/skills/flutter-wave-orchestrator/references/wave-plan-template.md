# Wave Plan: {YYYYMMDD}

## 対象ストーリー

| ID | タイトル | Priority |
|----|---------|----------|
| STORY-XXX | <タイトル> | High |
| STORY-YYY | <タイトル> | High |
| STORY-ZZZ | <タイトル> | Medium |

## ファイル競合マトリクス

| ファイル | STORY-XXX | STORY-YYY | STORY-ZZZ | 競合 |
|---------|-----------|-----------|-----------|------|
| lib/domain/xxx_repository.dart | 新規 | - | - | - |
| lib/domain/yyy_service.dart | - | 変更 | 変更 | YES |
| lib/presentation/shared_vm.dart | 変更 | 変更 | - | YES |

## 共有 Interface

Wave 0 で定義すべき共有 interface（**2つ以上のストーリーで使われるもののみ**）:
※ 1つのストーリーでしか使われない interface は各 Wave の「Architect Tasks」に記載

### 新規作成
- `lib/domain/xxx_repository.dart` - XxxRepository abstract class
  - 使用ストーリー: STORY-XXX, STORY-ZZZ

### 既存拡張
- `lib/domain/yyy_service.dart` - YyyService にメソッド追加
  - 使用ストーリー: STORY-YYY, STORY-ZZZ
  - 変更内容: <具体的な追加メソッドシグネチャ>

## 順序制約

- STORY-YYY → STORY-ZZZ
  - 理由: `yyy_service.dart` の変更を STORY-YYY で先行させ、STORY-ZZZ は拡張する形

## Git Worktree 戦略

```bash
# Wave 0 完了後（master にコミット済み）
git worktree add ../<project>-story-xxx -b feature/story-xxx
git worktree add ../<project>-story-yyy -b feature/story-yyy

# 各 worktree でセットアップ
cd ../<project>-story-xxx && flutter pub get
cd ../<project>-story-yyy && flutter pub get

# マージ順序: STORY-YYY → STORY-ZZZ → STORY-XXX
```

## Wave 0: 共有アーキテクチャ準備

- **Agent**: flutter-layer-first-architect
- **Tasks**:
  - [ ] 共有 interface 定義（上記「共有 Interface」セクション参照）
  - [ ] スタブ実装（NotImplementedError）
- **Gate**: `dart analyze` + `flutter test` パス + master コミット

## Wave 1: 並列実装

- **Architect Tasks**（Step 1.5 で worktree 上に実装）:
  - STORY-XXX 固有:
    - [ ] <ストーリー固有 interface / スタブ / TODO マーカー>
  - STORY-YYY 固有:
    - [ ] <ストーリー固有 interface / スタブ / TODO マーカー>

- **Stream A**: STORY-XXX
  - Agent: flutter-developer
  - Worktree: `../<project>-story-xxx`
  - Scope: <変更範囲の要約>

- **Stream B**: STORY-YYY
  - Agent: flutter-developer
  - Worktree: `../<project>-story-yyy`
  - Scope: <変更範囲の要約>

- **Gate**: 各 worktree で `dart analyze` + `flutter test` パス

## Wave 2: 依存実装

- **前提**: Wave 1 の STORY-YYY 完了 + master マージ済み
- **Architect Tasks**（Step 1.5 で worktree 上に実装）:
  - STORY-ZZZ 固有:
    - [ ] <ストーリー固有 interface / スタブ / TODO マーカー>
- **Tasks**: STORY-ZZZ（STORY-YYY の拡張部分を含む）
  - Agent: flutter-developer
  - Worktree: `../<project>-story-zzz`（master から新規作成）
- **Gate**: `dart analyze` + `flutter test` パス

## Wave 3: 統合レビュー

- [ ] 全ブランチ squash merge 済み
- [ ] `flutter pub get` → `dart analyze` → `flutter test` 全パス
- [ ] Gemini コードレビュー実行
- [ ] 重複コード・共通化可能な箇所のチェック

## Wave 4: Maestro E2E

- [ ] 既存フロー回帰テスト
- [ ] 新規フロー実行（各ストーリーの主要シナリオ）
