import SwiftUI

/// 月単位の 7 列ヒートマップ。
///
/// `sessions` は呼び出し側で当月分にフィルタしてから渡す前提。
/// 日付タップは `selectedDate` (Binding) に書き込まれる。
struct MonthCalendarView: View {
    let month: Date
    let sessions: [Session]
    @Binding var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let calendar = Calendar.current

    private var days: [MonthGridDay] {
        MonthGridGeometry.grid(for: month, calendar: calendar)
    }

    var body: some View {
        VStack(spacing: 8) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days, id: \.date) { day in
                    CalendarDayCell(
                        day: day,
                        minutesWorked: minutesWorked(on: day.date),
                        isSelected: isSelected(day.date),
                        onTap: { selectedDate = day.date }
                    )
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// ロケールの firstWeekday に合わせて並べ替えた曜日記号。
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    private func minutesWorked(on date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let total = sessions
            .filter { $0.startTime >= dayStart && $0.startTime < nextDay }
            .compactMap { $0.duration }
            .reduce(0, +)
        return Int(total / 60)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selectedDate)
    }
}
