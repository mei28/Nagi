import Foundation

/// 月カレンダーの 1 セルが表す日付情報。
struct MonthGridDay: Equatable {
    let date: Date
    let isInMonth: Bool
}

/// 月カレンダーの 7 列グリッドを組み立てる pure ヘルパ。
///
/// 戻り値の `days.count` は常に 7 の倍数 (28 / 35 / 42)。
/// `isInMonth` が false のセルは前月末 or 翌月初の埋め草。
enum MonthGridGeometry {
    static func grid(for month: Date, calendar: Calendar) -> [MonthGridDay] {
        let monthStart = startOfMonth(month, calendar: calendar)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        let daysInMonth = dayRange.count

        var days: [MonthGridDay] = []

        for offset in stride(from: leading, to: 0, by: -1) {
            if let date = calendar.date(byAdding: .day, value: -offset, to: monthStart) {
                days.append(MonthGridDay(date: date, isInMonth: false))
            }
        }

        for i in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: i, to: monthStart) {
                days.append(MonthGridDay(date: date, isInMonth: true))
            }
        }

        let trailing = (7 - days.count % 7) % 7
        for i in 0..<trailing {
            if let date = calendar.date(byAdding: .day, value: daysInMonth + i, to: monthStart) {
                days.append(MonthGridDay(date: date, isInMonth: false))
            }
        }

        return days
    }

    static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }
}
