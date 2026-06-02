# Nagi（凪）

[English](./README.md) | 日本語

> 自然な作業リズムを尊重するフロータイム式の作業時間管理アプリ。macOS 専用。

Nagi は Fathom（Tauri+React 製プロトタイプ）を SwiftUI でネイティブに作り直したものです。

- アプリ哲学: **Simple, Lovable, Complete (SLC)**
- 中心概念: **フロータイム** — 自然に作業 → 休憩は作業時間の N%（既定 20%）
- 全データはローカル保存、ネットワーク通信ゼロ

## 機能

| カテゴリ | 内容 |
|---------|------|
| タイマー | Time Timer 風の円形タイマー。作業中は周回ごとに色相シフト (青→インディゴ→紫→パープル)、休憩は緑系の濃→薄グラデーション (砂時計式) |
| 休憩提案 | 停止時に「作業時間 × 休憩比率」で自動算出。Start / Skip の 2 択でメモ入力フローを挟まない |
| 通知 | 休憩終了で `UNUserNotificationCenter` 通知 + サウンド (個別 ON/OFF) |
| 履歴 | 日付セクション分けされたリスト。追加 / 編集 / 削除、`endTime > startTime` バリデーション |
| カレンダー | 月単位ヒートマップ (5 段階の青) + 月ナビゲーション + Today ジャンプ。右パネルで日別セッション編集 |
| メニューバー | 常駐モード: タイマー操作 + 直近 10 週 GitHub 風ヒートマップ + 最近 5 件の inline メモ編集。Liquid Glass トーン |
| データ | Fathom 互換 JSON で Export / Import (Replace / Merge 選択)、2 段階確認の全削除 |
| 言語 | ja / en (システム連動 + 設定で手動切替) |

## 動作環境

- macOS 14 Sonoma 以降 (Apple Silicon / Intel)
- 開発: Xcode 16+ / Swift 5.9+ (PBXFileSystemSynchronizedRootGroup を使用)

## インストール (リリース版を使う)

### Homebrew (推奨)

```sh
brew install --cask mei28/nagi/nagi
```

未署名アプリなので、初回は Gatekeeper でブロックされることがあります。その場合は隔離属性を外して入れてください。

```sh
brew install --cask --no-quarantine mei28/nagi/nagi
```

### 手動 (zip)

1. [Releases](https://github.com/mei28/Nagi/releases) から `Nagi-<version>.zip` をダウンロード
2. zip を解凍 → `Nagi.app` を `/Applications` にドラッグ
3. 初回は Gatekeeper でブロックされるので、**右クリック → 開く** で承認
4. 通知の認可ダイアログを許可 (休憩終了通知のため)

## ビルド (ソースから動かす)

### 前提

```sh
# 必須
brew install just xcode-build-server xcbeautify

# Xcode.app を App Store からインストール後、コマンドラインツールを向ける
sudo xcode-select -s /Applications/Xcode.app
```

### 主要なコマンド

```sh
just doctor   # 環境チェック (xcodebuild / sourcekit-lsp / xcbeautify)
just lsp      # buildServer.json を生成 (nvim + sourcekit-lsp 用)
just build    # Debug ビルド
just run      # ビルドして起動 (open)
just run-fg   # 前景実行 (stdout が見える)
just run-ja   # 日本語ロケールで起動
just run-en   # 英語ロケールで起動
just test     # ユニットテスト (NagiTests のみ)
just release  # Release ビルド + dist/Nagi-<version>.zip
just install  # /Applications に配置
just clean    # 中間ファイル削除
just where    # ビルド成果物のパスを表示
just version 1.2.3  # MARKETING_VERSION を一括置換
```

## 使い方

### 基本フロー

1. **Start** で作業開始 → タイマーが回り始める
2. **Stop** で停止 → 提案された休憩時間が表示される
3. **Start break** で休憩開始、または **Skip** で次の作業へ
4. 休憩中はタイマーが時計回りに「縮んで」いく (砂時計式)。残り 0 で通知 + サウンド

### メモを書く

- メイン画面の Stop ではメモを入力しない
- History タブ (または Calendar タブの右パネル) のセッション行をタップ → 編集 sheet
- メニューバーの History セクションでは inline 編集も可能

### 設定 (Settings タブ)

- **Rotation**: タイマー 1 周の時間 (1 / 15 / 30 / 60 分)
- **Break ratio**: 休憩時間の割合 (1〜100%、既定 20%)
- **Notification / Sound**: 通知とサウンドの個別 ON/OFF
- **Language**: System / 日本語 / English (要再起動)
- **Data**: Fathom 互換 JSON の Export / Import / 全削除

### メニューバーモード

メニューバーの **N アイコン** をクリック:

- **Timer**: 現在の状態 + 大きな時計 + 状態に応じた primary ボタン
- **Calendar**: 直近 10 週の GitHub 風ヒートマップ
- **History**: 最近 5 件、メモは inline 編集、🗑 で即削除
- **Open Nagi…**: メインウィンドウを前面に
- **Quit Nagi**: アプリ終了

## ライセンス

[MIT License](./LICENSE)

## 名前について

「凪」 — 風や潮が止まる時間帯。集中と休息の "あいだ" を表す日本語。
