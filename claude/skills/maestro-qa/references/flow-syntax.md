# Maestro Flow 構文クイックリファレンス

## Flow ファイル構造

```yaml
appId: dev.ymdarake.time_tracker   # 必須: アプリID
name: "フロー名"                     # 任意: 表示名
---
# コマンド一覧 (YAML リスト)
- launchApp
- tapOn: "ボタン"
```

## コマンド一覧

### アプリ操作

```yaml
# アプリ起動
- launchApp

# 状態クリアして起動
- launchApp:
    clearState: true

# アプリ停止
- stopApp
```

### タップ

```yaml
# テキストでタップ
- tapOn: "開始"

# id (Semantics identifier) でタップ
- tapOn:
    id: "maestro_timer_start_button"

# 座標でタップ (非推奨)
- tapOn:
    point: "50%,50%"
```

### テキスト入力

> **制約**: `inputText` は **ASCII 文字のみ** 対応。日本語・マルチバイト文字は入力不可 (Maestro Issue #146)。
> テストでは英数字のみ使用すること。

```yaml
# テキスト入力 (フォーカス済みフィールドに、ASCII のみ)
- inputText: "project name"

# フィールドクリア
- eraseText
```

### アサーション

```yaml
# テキストが表示されている
- assertVisible: "稼働中"

# id で表示確認
- assertVisible:
    id: "maestro_timer_status_label"

# 非表示確認
- assertNotVisible: "休憩"

# タイムアウト付き
- assertVisible:
    text: "稼働中"
    timeout: 5000
```

### 待機

```yaml
# アニメーション完了待ち
- waitForAnimationToEnd

# 固定時間待機 (ミリ秒)
- wait:
    milliseconds: 2000
```

### スクロール

```yaml
# 下にスクロール
- scroll

# 上にスクロール
- scrollUntilVisible:
    element: "ターゲットテキスト"
    direction: DOWN
```

### サブフロー

```yaml
# 別フローを実行
- runFlow: ../shared/setup_project.yaml
```

### スクリーンショット

```yaml
# スクリーンショット保存
- takeScreenshot: "after_start"
```

### 条件分岐

```yaml
# 要素が表示されていたら実行
- runFlow:
    when:
      visible: "ダイアログタイトル"
    file: handle_dialog.yaml
```

## Key 命名規則 (このプロジェクト)

形式: `maestro_{画面名}_{要素名}`

> **重要**: Flutter の `ValueKey` は Maestro の `id` セレクタで検出できない。
> 必ず `Semantics(identifier: 'maestro_...')` を使用すること。
>
> **NavigationDestination の特殊ケース**: NavigationBar は destinations の型を
> NavigationDestination に限定しているため、NavigationDestination 自体を Semantics で
> ラップできない。代わりに `icon` パラメータをラップする。

例:
- `maestro_nav_timer_tab` - ナビゲーションバーのタイマータブ
- `maestro_timer_start_button` - タイマー画面の開始ボタン
- `maestro_settings_add_project_fab` - 設定画面のFAB