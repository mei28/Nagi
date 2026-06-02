import SwiftUI

/// カレンダー 1 セル。
///
/// その日の合計作業分数で塗りつぶし、Today はサブトルなボーダー、
/// 選択中は青枠を上書きする。前後月の埋め草セルは数字を薄くする。
struct CalendarDayCell: View {
    let day: MonthGridDay
    let minutesWorked: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: day.date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(CalendarHeatmapColor.color(forLevel: CalendarHeatmapColor.level(forMinutes: minutesWorked)))

                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.tint, lineWidth: 2)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.primary.opacity(0.35), lineWidth: 1)
                }

                Text("\(dayNumber)")
                    .font(.callout)
                    .foregroundStyle(day.isInMonth ? .primary : .tertiary)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateText = formatter.string(from: day.date)
        if minutesWorked == 0 {
            return String(localized: "\(dateText), no work")
        }
        return String(localized: "\(dateText), \(minutesWorked) minutes worked")
    }
}
