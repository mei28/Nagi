import Foundation

/// 作業時間から休憩時間の推奨値を計算する pure な型。
///
/// 計算は `workDuration × ratio` のみ。端数の丸めは呼び出し側
/// (表示レイヤー) に任せる。
enum BreakCalculator {
    static func suggestedBreak(
        workDuration: TimeInterval,
        ratio: Double
    ) -> TimeInterval {
        workDuration * ratio
    }
}
