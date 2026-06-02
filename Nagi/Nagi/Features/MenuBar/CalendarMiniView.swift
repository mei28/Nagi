import SwiftUI
import SwiftData

/// メニューバー用の GitHub 風ヒートマップ。
///
/// 直近 12 週 (= 84 日) を 7 曜日 × 12 列で表示。左に M / W / F の
/// スパース曜日ラベル (GitHub 流)。詳細は「Open Nagi…」でメイン画面の
/// Calendar タブを開いて見る。
struct CalendarMiniView: View {
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]

    private let weeksToShow = 10
    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3
    private let calendar = Calendar.current

    /// 列 (=週) ごとに 7 日 (Sun..Sat 順)。最古の週が左、最新が右。
    private var weeks: [[Date]] {
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let offsetToStartOfThisWeek = -((weekday - calendar.firstWeekday + 7) % 7)
        guard
            let startOfThisWeek = calendar.date(byAdding: .day, value: offsetToStartOfThisWeek, to: today),
            let firstWeekStart = calendar.date(byAdding: .day, value: -7 * (weeksToShow - 1), to: startOfThisWeek)
        else {
            return []
        }
        return (0..<weeksToShow).map { w in
            (0..<7).compactMap { d in
                calendar.date(byAdding: .day, value: w * 7 + d, to: firstWeekStart)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last \(weeksToShow) weeks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 6) {
                Spacer(minLength: 0)
                weekdayLabels
                heatmapGrid
                Spacer(minLength: 0)
            }
        }
    }

    private var weekdayLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<7, id: \.self) { d in
                Text(weekdayLabel(forRow: d))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .frame(width: 10, height: cellSize, alignment: .leading)
            }
        }
    }

    /// `firstWeekday` を考慮して、row=0 が calendar の週始まりになるよう
    /// Mon (=月) / Wed (=水) / Fri (=金) だけ表示する。
    private func weekdayLabel(forRow row: Int) -> String {
        // calendar.firstWeekday: 1=Sun, 2=Mon (地域による)
        // weekdaySymbols: 配列は [Sun, Mon, Tue, Wed, Thu, Fri, Sat]
        let absoluteWeekday = (row + calendar.firstWeekday - 1) % 7  // 0=Sun
        switch absoluteWeekday {
        case 1, 3, 5:
            let shortSymbols = calendar.veryShortWeekdaySymbols
            return shortSymbols[absoluteWeekday]
        default:
            return ""
        }
    }

    private var heatmapGrid: some View {
        HStack(alignment: .top, spacing: cellSpacing) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, days in
                VStack(spacing: cellSpacing) {
                    ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                        cell(for: date)
                    }
                }
            }
        }
    }

    private func cell(for date: Date) -> some View {
        let minutes = minutesWorked(on: date)
        let level = CalendarHeatmapColor.level(forMinutes: minutes)
        return RoundedRectangle(cornerRadius: 2)
            .fill(CalendarHeatmapColor.color(forLevel: level))
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if calendar.isDateInToday(date) {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(.primary.opacity(0.55), lineWidth: 1)
                }
            }
            .help(tooltip(for: date, minutes: minutes))
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

    private func tooltip(for date: Date, minutes: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateText = formatter.string(from: date)
        if minutes == 0 { return "\(dateText) — \(String(localized: "No sessions"))" }
        let h = minutes / 60
        let m = minutes % 60
        let duration = h > 0 ? "\(h)h \(m)m" : "\(m)m"
        return "\(dateText) — \(duration)"
    }
}
