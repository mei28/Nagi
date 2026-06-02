import Testing
import Foundation
@testable import Nagi

@MainActor
struct SessionGroupingTests {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    /// 2023-11-15 hh:00:00 UTC を組み立てる。
    private func date(year: Int = 2023, month: Int = 11, day: Int = 15,
                      hour: Int = 9, minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        return calendar.date(from: comps)!
    }

    private func session(at start: Date) -> Session {
        Session(startTime: start, createdAt: start, updatedAt: start)
    }

    @Test
    func empty_input_returns_empty_groups() {
        let groups = SessionGrouping.byDay([], calendar: calendar)
        #expect(groups.isEmpty)
    }

    @Test
    func single_session_returns_one_group() {
        let t = date(hour: 10)
        let groups = SessionGrouping.byDay([session(at: t)], calendar: calendar)

        #expect(groups.count == 1)
        #expect(groups[0].sessions.count == 1)
        #expect(groups[0].date == calendar.startOfDay(for: t))
    }

    @Test
    func same_day_sessions_are_in_same_group_sorted_descending() {
        let morning = session(at: date(hour: 9))
        let noon = session(at: date(hour: 13))
        let evening = session(at: date(hour: 18))

        let groups = SessionGrouping.byDay([morning, evening, noon], calendar: calendar)

        #expect(groups.count == 1)
        #expect(groups[0].sessions.map(\.id) == [evening.id, noon.id, morning.id])
    }

    @Test
    func different_days_are_split_and_dates_descending() {
        let s14 = session(at: date(day: 14, hour: 10))
        let s15 = session(at: date(day: 15, hour: 10))
        let s16 = session(at: date(day: 16, hour: 10))

        let groups = SessionGrouping.byDay([s14, s15, s16], calendar: calendar)

        #expect(groups.count == 3)
        #expect(groups[0].date == calendar.startOfDay(for: date(day: 16)))
        #expect(groups[1].date == calendar.startOfDay(for: date(day: 15)))
        #expect(groups[2].date == calendar.startOfDay(for: date(day: 14)))
    }

    @Test
    func sessions_just_before_and_after_midnight_split_into_two_days() {
        let beforeMidnight = session(at: date(day: 15, hour: 23, minute: 30))
        let afterMidnight = session(at: date(day: 16, hour: 0, minute: 30))

        let groups = SessionGrouping.byDay([beforeMidnight, afterMidnight], calendar: calendar)

        #expect(groups.count == 2)
        #expect(groups[0].sessions.first?.id == afterMidnight.id)
        #expect(groups[1].sessions.first?.id == beforeMidnight.id)
    }
}
