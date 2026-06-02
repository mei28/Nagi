import SwiftUI

/// カレンダーセルの彩度を 5 段階で表すヘルパ。
///
/// 閾値 (分):
///   0       → level 0 (作業なし)
///   1..59   → level 1
///   60..179 → level 2
///   180..299→ level 3
///   300+    → level 4
///
/// 色は `Theme.workingAccent` (= 青) を不透明度で 5 段階に。
/// OPEN_QUESTIONS.md Q11 で「タイマーと同系統の青グラデーション」と決定済み。
enum CalendarHeatmapColor {
    static func level(forMinutes minutes: Int) -> Int {
        switch minutes {
        case 0: 0
        case 1..<60: 1
        case 60..<180: 2
        case 180..<300: 3
        default: 4
        }
    }

    static func color(forLevel level: Int) -> Color {
        switch level {
        case 0: Color.gray.opacity(0.10)
        case 1: Theme.workingAccent.opacity(0.25)
        case 2: Theme.workingAccent.opacity(0.50)
        case 3: Theme.workingAccent.opacity(0.75)
        default: Theme.workingAccent
        }
    }
}
