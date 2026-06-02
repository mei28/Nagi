import SwiftUI

/// Nagi のテーマ (色パレットなど)。
///
/// 色を調整したいときは下の「設定セクション」だけ触れば OK。
/// 公開 API はパレット配列をインデックスで引くだけのシンプルな実装なので、
/// 配列を書き換えれば即座に CircularTimerView の見た目に反映される。
/// 配列長を超える周回番号が来たら末尾色に固定される。
///
/// ライト/ダーク両対応はシステムカラー (`.blue` 等) の自動切替に任せる。
/// HSB 指定の独自色はリテラルなので両モードで同じ見た目になる。
enum Theme {

    // ============================================================
    // MARK: - 設定セクション (色のカスタマイズはここだけ編集)
    // ============================================================

    // MARK: 状態色 (外枠色 / FR-5.1)

    static let idleAccent: Color = .gray.opacity(0.5)
    static let workingAccent: Color = .blue
    static let breakAccent: Color = .green

    // MARK: 周回色パレット (FR-5.2)

    /// Working 中の周回色パレット。
    /// 色相シフトでアクティブな進行感を出す方針 (青 → インディゴ → 紫 → パープル)。
    static let rotationPalette: [Color] = [
        .blue,
        .indigo,
        .purple,
        Color(red: 0.85, green: 0.3, blue: 0.85),
    ]

    /// Break 中の周回色パレット。
    /// 色相を緑に固定して、彩度と明度を下げ濃 → 薄のグラデーションで進行感を出す方針。
    static let breakRotationPalette: [Color] = [
        Color(hue: 0.39, saturation: 0.90, brightness: 0.50),  // 濃い緑
        Color(hue: 0.39, saturation: 0.70, brightness: 0.70),  // ミディアム
        Color(hue: 0.39, saturation: 0.50, brightness: 0.85),  // ライト
        Color(hue: 0.39, saturation: 0.25, brightness: 0.97),  // 最も淡い
    ]

    // MARK: 描画パラメータ

    /// 完了済み周回の塗りつぶしの不透明度 (Working / Break 共通)。
    static let completedRotationOpacity: Double = 0.35

    // ============================================================
    // MARK: - 公開 API (通常は触らない)
    // ============================================================

    static func accent(for state: TimerVisualState) -> Color {
        switch state {
        case .idle: idleAccent
        case .working: workingAccent
        case .pendingBreak, .onBreak: breakAccent
        }
    }

    static func rotationColor(at index: Int) -> Color {
        color(in: rotationPalette, at: index)
    }

    static func breakRotationColor(at index: Int) -> Color {
        color(in: breakRotationPalette, at: index)
    }

    private static func color(in palette: [Color], at index: Int) -> Color {
        let safe = max(0, min(index, palette.count - 1))
        return palette[safe]
    }
}
