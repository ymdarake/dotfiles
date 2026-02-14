# DDD Architecture Review Prompt

## プロンプトテンプレート

```
このリポジトリの git diff を確認し、DDDアーキテクチャレビューを実施してください。
staged changes がある場合は git diff --cached も確認してください。
必要に応じて変更ファイルの全文も読んで文脈を把握してください。

このプロジェクトは Layer-first DDD風アーキテクチャを採用しています。

## ディレクトリ構成

lib/
├── ui/           # UI層（page, atom, compound, layout）
├── domain/       # Domain層（interface のみ。実装なし）
├── use_case/     # Use Case層（Service の実装）
└── infrastructure/ # Infrastructure層（Repository の実装）

## レビュー観点

### 依存方向の違反
- Domain層（lib/domain/）に Flutter/外部パッケージの import がないか
  - 許可: dart:core, domain 内の相互参照のみ
  - 違反例: `import 'package:flutter/...';`, `import 'package:firebase_auth/...';`
- UI層（lib/ui/）が infrastructure 層を直接参照していないか
  - 違反例: `import 'package:xxx/infrastructure/...';`
- use_case 層が infrastructure 層を直接参照していないか
  - 違反例: `import 'package:xxx/infrastructure/...';`

### ViewModel の責務違反
- ViewModel が Repository を直接呼び出していないか（Service 経由であるべき）
  - 例外: Repository の単一メソッド呼び出しで完結し、追加ロジックがない場合
- ViewModel 内でビジネスロジック（条件分岐、計算等）を実装していないか

### Result パターンの適用
- Service/Repository のメソッドが例外を throw せず Result を返しているか
- ViewModel で Result のパターンマッチング（switch）が適切に行われているか
- エラー型が sealed class で定義されているか

### interface と実装の分離
- domain 層に具象クラス（impl）が混入していないか
- infrastructure 層のクラスが正しく domain の interface を implements しているか

## 依存ルール

正しい依存方向:
  ui/page → domain（interface のみ）
  use_case → domain（interface を実装）
  infrastructure → domain（interface を実装）

禁止される依存:
  ui → use_case（直接依存禁止）
  ui → infrastructure（直接依存禁止）
  domain → use_case（逆方向禁止）
  domain → infrastructure（逆方向禁止）

## 出力形式
各指摘を以下の形式で:
- **重要度**: Critical / High / Medium / Low
- **違反種別**: 依存方向 / 責務 / Result未適用 / interface分離
- **ファイル**: ファイルパス:行番号
- **問題**: 具体的なDDD違反の説明
- **修正案**: 具体的な修正方針

DDD違反がない場合は「DDDアーキテクチャ上の問題は見つかりませんでした」と回答してください。
```
