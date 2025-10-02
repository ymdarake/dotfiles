# プロジェクト設定 (TypeScript)

TypeScriptプロジェクト用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] 言語: TypeScript
- [ ] フレームワーク: (例: React, Next.js, Express, NestJS など)
- [ ] その他: (例: PostgreSQL, Redis, Docker など)

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## Bashコマンド

<!-- ⚠️ 【要記入】プロジェクトで実際に使うコマンドに修正してください -->

```bash
npm run dev            # 開発サーバーを起動
npm run build          # プロダクションビルド
npm test               # テストを実行
npm run test:watch     # watchモードでテスト実行
npm run typecheck      # 型チェックを実行
npm run lint           # ESLintを実行
npm run format         # Prettierでフォーマット
npm run format:check   # フォーマットチェック
```

## プロジェクト構成

<!-- ⚠️ 【要記入】プロジェクトの実際のディレクトリ構造を記入してください -->

- `src/` - ソースコード
  - `index.ts` - エントリーポイント
  - `components/` - コンポーネント（React/Vue等）
  - `types/` - 型定義
  - `utils/` - ユーティリティ関数
  - `hooks/` - カスタムフック（React）
  - `services/` - API通信・ビジネスロジック
  - `constants/` - 定数定義
- `tests/` - テストコード
- `public/` - 静的ファイル
- `dist/` - ビルド出力

## コーディングスタイル

- ES modules (import/export) を使用
- インポートは分割代入を優先
- 関数名: camelCase
- クラス名・型名: PascalCase
- 定数: UPPER_SNAKE_CASE
- インターフェース: `I` プレフィックスなし（例: `User` not `IUser`）
- Enum より Union Types や const assertions を優先

## 型定義

```typescript
// 明示的な型定義を優先
const userId: string = "123";

// any は避け、unknown を使用
function processData(data: unknown) { }

// 型ガードを活用
if (typeof value === "string") { }

// Generics を活用
function identity<T>(arg: T): T {
  return arg;
}
```

## React プロジェクト（該当する場合）

- Functional Component を使用
- Hooks を活用（useState, useEffect等）
- Props の型定義は必須
- `React.FC` より明示的な型定義を推奨

```typescript
interface Props {
  name: string;
  age?: number;
}

export const MyComponent = ({ name, age }: Props) => {
  return <div>{name}</div>;
};
```

## テスト方針

- テストフレームワーク: Jest / Vitest
- 新機能追加時はテストも追加
- カバレッジ80%以上を目標
- E2Eテスト: Playwright / Cypress

## Linting & Formatting

- ESLint で静的解析
- Prettier で自動フォーマット
- コミット前にチェック（husky + lint-staged）

## 依存管理

- package.json で管理
- 不要な依存は削除
- セキュリティ脆弱性を定期チェック（`npm audit`）

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*
