import SwiftUI
import SwiftData

/// カレンダー画面。
///
/// 左側: 月ナビゲーション + ヒートマップ
/// 右側: 選択日のセッション一覧 (`SessionRow` を再利用)
///
/// 月をまたぐ遷移は < / > ボタン、Today ボタンで現在月へジャンプ。
struct CalendarScreen: View {
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]
    @Environment(\.modelContext) private var modelContext

    @State private var currentMonth: Date = .now
    @State private var selectedDate: Date? = .now
    @State private var editor: EditorPresentation?

    /// sheet 表示用の Identifiable wrapper (HistoryScreen と同じパターン)。
    struct EditorPresentation: Identifiable {
        let id = UUID()
        let session: Session
    }

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                calendarPanel
                Divider()
                sessionsPanel
            }
            .navigationTitle("Calendar")
        }
        .sheet(item: $editor) { presentation in
            SessionEditorView(mode: .edit(presentation.session))
        }
    }

    private var calendarPanel: some View {
        VStack(spacing: 16) {
            monthNavigation
            MonthCalendarView(
                month: currentMonth,
                sessions: sessionsInCurrentMonth,
                selectedDate: $selectedDate
            )
            Spacer()
            #if DEBUG
            debugTools
            #endif
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }

    #if DEBUG
    private var debugTools: some View {
        HStack(spacing: 12) {
            Text("Debug")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button("Seed 60 days") {
                DebugSeeding.seed(into: modelContext)
            }
            .controlSize(.small)
            Button("Clear all", role: .destructive) {
                DebugSeeding.clearAll(from: modelContext)
                selectedDate = .now
            }
            .controlSize(.small)
        }
    }
    #endif

    private var sessionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedDate {
                Text(dayHeader(selectedDate))
                    .font(.title3.weight(.semibold))

                let daySessions = sessionsOnSelectedDate(selectedDate)
                if daySessions.isEmpty {
                    Text("No sessions")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(daySessions, id: \.id) { session in
                            SessionRow(session: session)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editor = EditorPresentation(session: session)
                                }
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                ContentUnavailableView(
                    "Select a date",
                    systemImage: "calendar",
                    description: Text("Tap a day to see its sessions.")
                )
            }
        }
        .padding(20)
        .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
    }

    private var monthNavigation: some View {
        HStack(spacing: 8) {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(monthTitle)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)

            // 今月かつ今日を選択しているときは Today ボタン不要。
            // それ以外 (別月、または今月でも今日以外を選択) では表示。
            // 配置が動かないよう opacity で見せ消しする。
            Button("Today", action: jumpToToday)
                .controlSize(.small)
                .buttonStyle(.bordered)
                .opacity(isViewingToday ? 0 : 1)
                .allowsHitTesting(!isViewingToday)
        }
    }

    private var isViewingToday: Bool {
        guard let selectedDate else { return false }
        let monthMatches = calendar.isDate(currentMonth, equalTo: .now, toGranularity: .month)
        return monthMatches && calendar.isDateInToday(selectedDate)
    }

    private func jumpToToday() {
        currentMonth = MonthGridGeometry.startOfMonth(.now, calendar: calendar)
        selectedDate = .now
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonth)
    }

    private var sessionsInCurrentMonth: [Session] {
        let start = MonthGridGeometry.startOfMonth(currentMonth, calendar: calendar)
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return sessions.filter { $0.startTime >= start && $0.startTime < end }
    }

    private func sessionsOnSelectedDate(_ date: Date) -> [Session] {
        let dayStart = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return sessions
            .filter { $0.startTime >= dayStart && $0.startTime < nextDay }
            .sorted { $0.startTime > $1.startTime }
    }

    private func changeMonth(by delta: Int) {
        if let new = calendar.date(byAdding: .month, value: delta, to: currentMonth) {
            currentMonth = new
        }
    }

    private static let dayHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private func dayHeader(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return String(localized: "Today") }
        if calendar.isDateInYesterday(date) { return String(localized: "Yesterday") }
        return Self.dayHeaderFormatter.string(from: date)
    }
}
