# Architect Wave 計画策定プロンプト

Phase 2 で Architect エージェントに Wave 計画策定を依頼する際のプロンプトテンプレート。

## 依頼プロンプト

```
Task tool → flutter-layer-first-architect:
"複数ストーリーの Wave 並列実装を計画してください。
各ストーリーの影響分析（Plan）を読み込み、以下を策定してください。

## 対象ストーリー
- [STORY-XXX] <タイトル> → docs/plans/STORY-XXX.md
- [STORY-YYY] <タイトル> → docs/plans/STORY-YYY.md
- [STORY-ZZZ] <タイトル> → docs/plans/STORY-ZZZ.md

## BACKLOG.md の AC
<各ストーリーの Gherkin AC を貼り付け>

## 依頼事項

### 1. 競合分析
各ストーリーの Plan から変更対象ファイルを抽出し、ファイル競合マトリクスを作成してください。
- どのファイルがどのストーリーで変更されるか
- 競合するファイルの一覧と競合の性質（追加 vs 変更、同一メソッド vs 別メソッド）

### 2. 共有 interface の特定
競合分析を踏まえ、複数ストーリーで必要な共有 interface を特定してください。
- Repository / Service の abstract class
- Domain Entity / Value Object の拡張
- Provider の追加・変更

### 3. Wave 分割
以下のルールで Wave を分割してください:
- Wave 0: 共有 interface 定義 + スタブ実装（あなたが実行）
- Wave 1: 競合のないストーリーを並列グループに分類
- Wave 2+: Wave 1 の結果に依存するストーリー
- 各 Wave の品質ゲート条件を明記

### 4. Git Worktree 戦略
Wave 1+ で使用する git worktree のセットアップ手順を定義してください。
- ブランチ命名規則
- worktree のディレクトリ配置
- マージ順序

### 5. 順序制約
Wave 間の依存関係と、その理由を明記してください。

## 出力形式
以下のフォーマットに従って出力してください:

### 必須セクション
1. **対象ストーリー** - ID、タイトル、Priority の一覧表
2. **ファイル競合マトリクス** - ファイル × ストーリーの変更有無 + 競合判定
3. **共有 Interface** - Wave 0 で定義すべき interface（新規作成 / 既存拡張）
4. **順序制約** - Wave 間の依存関係と理由
5. **Git Worktree 戦略** - ブランチ命名、worktree ディレクトリ配置、マージ順序
6. **Wave 0〜N の定義** - 各 Wave の Agent、Tasks、品質ゲート条件"
```

## コンテキストウィンドウ対策

ストーリー数が 5 以上の場合、Architect への依頼を 2 ステップに分割する:

1. **Step A: 競合分析のみ**
   - 各 Plan の「変更箇所の候補」セクションのみを抜粋して渡す
   - 出力: ファイル競合マトリクス + 順序制約

2. **Step B: Wave 計画策定**
   - Step A の出力 + 全 Plan を渡す
   - 出力: 完全な Wave 計画書
