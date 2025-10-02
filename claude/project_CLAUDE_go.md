# プロジェクト設定 (Go)

Goプロジェクト用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## Bashコマンド

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

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*
