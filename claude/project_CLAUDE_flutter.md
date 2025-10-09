# プロジェクト設定 (Flutter)

Flutterプロジェクト用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] 言語: Dart
- [ ] フレームワーク: Flutter
- [ ] 状態管理: (例: Provider, Riverpod, BLoC など)
- [ ] その他: (例: Firebase, GraphQL など)

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## Bashコマンド

<!-- ⚠️ 【要記入】プロジェクトで実際に使うコマンドに修正してください -->

```bash
flutter run                    # アプリを起動
flutter run -d ios             # iOSシミュレータで起動
flutter run -d android         # Androidエミュレータで起動
flutter build apk              # Android APKをビルド
flutter build ios              # iOSビルド
flutter test                   # 全テストを実行
flutter analyze                # 静的解析
flutter pub get                # 依存関係をインストール
flutter pub upgrade            # 依存関係を更新
flutter clean                  # ビルドキャッシュをクリア
dart format lib/               # コードフォーマット
```

## プロジェクト構成

<!-- ⚠️ 【要記入】プロジェクトの実際のディレクトリ構造を記入してください -->

- `lib/` - アプリケーションコード
  - `main.dart` - エントリーポイント
  - `screens/` - 画面ウィジェット
  - `widgets/` - 再利用可能なウィジェット
  - `models/` - データモデル
  - `services/` - ビジネスロジック・API通信
  - `providers/` - 状態管理（Provider使用時）
  - `utils/` - ユーティリティ
- `test/` - ユニットテスト
- `integration_test/` - 統合テスト
- `assets/` - 画像・フォント等
- `pubspec.yaml` - 依存関係定義

## コーディングスタイル

- Dart の公式スタイルガイドに従う
- `dart format` でフォーマット
- クラス名: UpperCamelCase
- 変数・関数名: lowerCamelCase
- 定数: lowerCamelCase（`const` キーワード使用）
- プライベート: アンダースコア始まり（`_privateMethod`）

## ウィジェット設計

- StatelessWidget を優先
- 状態が必要な場合のみ StatefulWidget
- ウィジェットは小さく、再利用可能に
- `const` コンストラクタを積極的に使用（パフォーマンス向上）

## 状態管理

- Provider / Riverpod / BLoC などを使用
- グローバルな状態は最小限に
- 画面固有の状態は画面内で管理

## テスト方針

- ユニットテスト: ビジネスロジック、モデル
- ウィジェットテスト: UI コンポーネント
- 統合テスト: 重要なユーザーフロー
- テストカバレッジ70%以上を目標

## null safety

- Dart 2.12+ の null safety を使用
- `?` nullable、`!` non-null assertion
- late 初期化は慎重に使用

---

## アーキテクチャ指針（Flutter）

- 目的: Widget をシンプルにし、データ操作を UseCase へ集約。保存先（SharedPreferences/Isar/HTTP/Memory）を差し替え可能に。
- レイヤ構成:
  - Presentation（Widget/StateNotifier/BLoC/Cubit）
    - ↓ Application（UseCase）
      - ↓ Domain（Repository 抽象/Entity/Value）
        - ↓ Infrastructure（具体実装: SharedPreferences/Isar/HTTP/Memory）
- Riverpod（または get_it）で Composition Root に依存を束ね、Provider で注入。
- Contract Test（Repository 抽象）→ UseCase Test（Clock 固定）→ Widget Test（Provider オーバーライド）の順で担保。

## ディレクトリ構造（例）

```
lib/
  presentation/                 // Widget/Route/State管理（Riverpod/BLoC等）
    pages/
    widgets/
    providers/
  application/                  // UseCase
    usecase/
      save_score.dart
      load_rankings.dart
  domain/                       // 抽象・モデル
    ranking/
      ranking_entry.dart
      ranking_repository.dart   // 抽象
      types.dart
  infrastructure/               // 具体実装
    ranking/
      shared_prefs/
        ranking_repository.dart
      http/
        ranking_repository.dart
      memory/
        ranking_repository.dart
  shared/
    clock.dart
  main.dart                     // Composition Root（Provider束ね）
```
