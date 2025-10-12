# プロジェクト設定

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] 言語: (例: TypeScript, Go, Python, Rust など)
- [ ] フレームワーク: (例: React, Next.js, Express, Echo など)
- [ ] その他: (例: データベース、インフラツールなど)

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## Bashコマンド

<!-- ⚠️ 【要記入】プロジェクトで使うコマンドを記入してください -->

```bash
npm run build          # プロジェクトをビルド（※例: npmの場合）
npm run dev            # 開発サーバーを起動
npm test               # テストを実行
npm run typecheck      # 型チェックを実行
npm run lint           # Lintを実行
```

## コアファイルとディレクトリ構造

<!-- ⚠️ 【要記入】プロジェクトのディレクトリ構造を記入してください -->

- `src/` - ソースコード
- `tests/` - テストコード
- `docs/` - ドキュメント
- `config/` - 設定ファイル

## コーディングスタイル

- インデント: スペース2つ
- モジュール: ES modules (import/export) を使用
- インポート: 可能な限り分割代入を使用
- 関数名: camelCase
- 定数: UPPER_SNAKE_CASE
- コメントは日本語可

## テスト方針

- 新機能追加時はテストも追加
- テスト実行: `npm test`
- カバレッジ確認: `npm run coverage`

## Git運用

- ブランチ戦略: GitHub Flow
- コミットメッセージは日本語で記述
- gitmoji を使用する（:wrench:, :bug:, :sparkles: など）
- コミット前にテスト実行
- プルリクエストは詳細な説明を記載

---

## アーキテクチャ指針（一般・UI非依存）

本プロジェクトの基本方針（Repository / UseCase / DI）は UI 技術に依存しません。目的は以下です。
- UI とデータ操作を分離しテスト容易性・保守性を向上
- 保存先（ファイル/DB/HTTP/メモリ）の差し替えを可能に
- 日付付与・検証・整形などのアプリ手続きを UseCase に集約

### レイヤ構成（依存方向）
- Presentation（UI/CLI/API Handler 等）
  - ↓ Application（UseCase）
    - ↓ Domain（Repository 抽象/エンティティ/バリュー）
      - ↓ Infrastructure（Repository 具体実装: DB/HTTP/FS/Memory 等）

依存は常に上から下の一方向。Presentation は具体実装を知らず、抽象（インターフェイス）越しにやり取りします。

### 典型ディレクトリ構造（例）
```
app/
  presentation/
  application/
    usecase/
  domain/
    ranking/
      entity.ts
      repository.ts
  infrastructure/
    ranking/
      memory/
      file/
      http/
  shared/
    clock.ts
  main.ts
```

### 主要インターフェイス例（概念）
- Domain の `Repository` は永続化境界を抽象化し、UseCase はアプリ手続きを薄く表現します。
- Composition Root（起動点）で具体実装と依存（Clock 等）を生成・注入します。

### テスト戦略
1) Contract Test: Repository 抽象に対し InMemory/実装が同一振る舞いか検証
2) UseCase Test: Clock を固定し、副作用（日時付与/整形）を検証
3) Presentation Test: Handler/CLI/画面が UseCase 結果を正しく描画/返却

### 注意点
- エラーは層境界で適切に変換
- ロギング/メトリクスは UseCase 境界へ集約


## References
- Project Rules: `https://docs.cursor.com/ja/context/rules`
- 解説: `https://zenn.dev/globis/articles/cursor-project-rules`
