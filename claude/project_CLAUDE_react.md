# プロジェクト設定 (React)

React プロジェクト用のガイドとして `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] 言語: TypeScript
- [ ] フレームワーク: React
- [ ] 状態管理/データ取得: Context / Custom Hooks / （必要に応じて）React Query/SWR
- [ ] その他: （例: Vite/Next.js、ESLint、Prettier）

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## データアーキテクチャ（Repository / UseCase / Context / Hook）

目的:
- UI とデータ操作の分離（疎結合）
- Repository の差し替え（LocalStorage → API 等）
- 日付付与・整形・検証などを UseCase に集約（ポリシー一元化）

### レイヤ構成（依存方向）
- UI Component（React Component）
  - ↓ Hook（例: `useRanking`）
    - ↓ Context（DI された Repository へのアクセスポイント）
      - ↓ UseCase（ビジネスアプリケーション操作・薄い）
        - ↓ Repository（データ操作の抽象；Domain インターフェイス）
          - ↓ Infrastructure（LocalStorage など具体実装）

依存は上から下へ一方向。UI は具体 Repository を知らず、Context/Hook を介して抽象に触れます。

### 主要インターフェイス（概念）
```ts
export interface RankingRepository {
  getRankings(difficulty?: Difficulty): Promise<RankingEntry[]>;
  saveRanking(newEntry: RankingEntry, difficulty?: Difficulty): Promise<RankingEntry[]>;
}
```

### UseCase（薄い手続き）
- `SaveScoreUseCase`: Clock で日時を付与し、Repository に委譲
- `LoadRankingsUseCase`: 取得を委譲し、UI 非依存に保つ

### Context と Hook
- Context: 具体 Repository を Composition Root で生成し Provider で注入
- Hook: 取得/キャッシュ/ローディング制御を再利用可能にまとめる（`useRanking` など）

### Composition Root（例）
- `index.tsx` で `new LocalStorageRankingRepository()` を生成し Provider に渡す
- 将来 API 実装へ差し替えても UI の変更は最小限

### テスト戦略
1) Contract Test: Repository 抽象に対し InMemory/LocalStorage 実装の同一性を検証
2) UseCase Test: Clock 固定で副作用（日時付与/整形）を検証
3) Hook Test: Provider で Stub Repository を注入し、ローディング/エラー/キャッシュを検証
4) Component Test: Hook の結果レンダリングを確認

### ディレクトリ例
```
src/
  domain/
    ranking/
      RankingRepository.ts
      types.ts
  repository/
    localstorage/
    memory/
  usecase/
    saveScore.ts
    loadRankings.ts
  context/
    RankingRepositoryContext.tsx
  hooks/
    useRanking.ts
  app/
    index.tsx
```

### ポイント
- View は UseCase を直接呼ぶか Hook 経由で利用し、Repository 具体型を知らない
- 仕様変更や実装差し替えの影響を UseCase 境界内に局所化
- 観測（メトリクス/監査ログ）は UseCase に集約
