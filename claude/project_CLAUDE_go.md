# プロジェクト設定 (Go)

Goプロジェクト用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] 言語: Go
- [ ] フレームワーク: (例: Echo, Gin, Chi, gRPC など)
- [ ] その他: (例: PostgreSQL, Redis, Docker など)

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## Bashコマンド

<!-- ⚠️ 【要記入】プロジェクトで実際に使うコマンドに修正してください -->

```bash
go build ./...         # プロジェクト全体をビルド
go test ./...          # 全テストを実行
go test -v ./...       # 詳細出力でテスト実行
go test -cover ./...   # カバレッジ付きでテスト実行
go run main.go         # メインを実行
go mod tidy            # 依存関係を整理
go fmt ./...           # コードフォーマット
go vet ./...           # 静的解析
golangci-lint run      # Lintを実行（インストール済みの場合）
```

## プロジェクト構成

<!-- ⚠️ 【要記入】プロジェクトの実際のディレクトリ構造を記入してください -->

- `cmd/` - エントリーポイント（main.go）
- `internal/` - 内部パッケージ
- `pkg/` - 外部公開パッケージ
- `api/` - API定義
- `test/` - 統合テスト
- `go.mod` - モジュール定義

## コーディングスタイル

- `gofmt` でフォーマット済み
- パッケージ名: 小文字、単一単語
- インターフェース名: `~er` で終わる（Reader, Writer など）
- エクスポート: 大文字開始（Public）、小文字開始（private）
- エラーハンドリング: 明示的に処理、`panic` は避ける
- コメント: エクスポートされた関数・型には必ずコメント

## テスト方針

- テストファイル: `*_test.go`
- テーブル駆動テスト推奨
- モックは `interface` で定義
- カバレッジ80%以上を目標

## 依存管理

- Go modules を使用
- 外部依存は最小限に
- `go mod tidy` で不要な依存を削除

## エラーハンドリング

```go
// エラーのラップ
if err != nil {
    return fmt.Errorf("failed to process: %w", err)
}

// カスタムエラー型を定義
type MyError struct {
    Code    int
    Message string
}
```

---

## アーキテクチャ指針（Go）

- 目的: Handler（入出力）からデータ操作を分離しテスト容易性を向上。保存方法（DB/FS/HTTP/Memory）の差し替えを容易に。
- レイヤ構成:
  - Interface Adapter（HTTP/CLI 等）
    - ↓ Application（UseCase）
      - ↓ Domain（Repository 抽象/Entity/Value）
        - ↓ Infrastructure（具体: DB/FS/HTTP/Memory）
- Composition Root（起動点）で具体 Repository と Clock 等の依存を生成・注入。
- Contract Test（抽象に対する InMemory/実装の同一性）→ UseCase Test（Clock 固定）→ Handler テストの順で担保。

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*

## ディレクトリ構造（例）

```
cmd/app/                        # エントリポイント（main）
internal/
  interface/                   # ハンドラ/CLI等の入出力境界
    http/
      handler.go
    cli/
      command.go
  application/                 # UseCase
    usecase/
      save_score.go
      load_rankings.go
  domain/                      # 抽象・モデル
    ranking/
      entity.go
      repository.go           # interface RankingRepository
      types.go
  infrastructure/              # 具体実装
    ranking/
      memory/
        repository.go
      file/
        repository.go
      db/
        repository.go
shared/
  clock/
    clock.go
```
