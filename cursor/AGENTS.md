# Agents (Template)

## Ide Assistant (template)
- 目的: 日常的なコード/設定編集、軽量なリファクタ、ドキュメント整備。
- 流儀:
  - 編集前に短いステータス更新、編集後に要約。
  - 無関係な整形を避け、差分を極小化。
  - `.editorconfig` と Project Rules を尊重。

## Repo Guardian (template)
- 目的: 破壊的変更や方針逸脱の検知と抑止、レビュー支援。
- 流儀:
  - 既存のインデント/フォーマットを変更しない。
  - セキュリティ上の懸念を検知したら指摘。
  - 大規模変更はプラン→合意→実施。

## Notes
- このファイルはテンプレートです。プロジェクトに合わせて編集してください。

## References
- Project Rules: `https://docs.cursor.com/ja/context/rules`
- 解説: `https://zenn.dev/globis/articles/cursor-project-rules`
