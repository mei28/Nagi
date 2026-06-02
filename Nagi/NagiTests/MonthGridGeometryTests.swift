import Testing
import Foundation
@testable import Nagi

struct MonthGridGeometryTests {

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 1  // Sunday
        return cal
    }

    private func date(year: Int, month: Int, day: Int = 1) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return calendar.date(from: comps)!
    }

    @Test
    func grid_length_is_multiple_of_seven() {
        let days = MonthGridGeometry.grid(for: date(year: 2024, month: 6), calendar: calendar)
        #expect(days.count % 7 == 0)
    }

    @Test
    func grid_contains_all_days_of_month() {
        let days = MonthGridGeometry.grid(for: date(year: 2024, month: 1), calendar: calendar)
        let inMonth = days.filter(\.isInMonth)
        #expect(inMonth.count == 31)
    }

    @Test
    func february_in_leap_year_has_29_days() {
        let days = MonthGridGeometry.grid(for: date(year: 2024, month: 2), calendar: calendar)
        let inMonth = days.filter(\.isInMonth)
        #expect(inMonth.count == 29)
    }

    @Test
    func february_in_non_leap_year_has_28_days() {
        let days = MonthGridGeometry.grid(for: date(year: 2023, month: 2), calendar: calendar)
        let inMonth = days.filter(\.isInMonth)
        #expect(inMonth.count == 28)
    }

    @Test
    func when_month_starts_on_sunday_leading_padding_is_zero() {
        // 2023-10-01 is Sunday
        let days = MonthGridGeometry.grid(for: date(year: 2023, month: 10), calendar: calendar)
        #expect(days.first?.isInMonth == true)
    }

    @Test
    func when_month_starts_on_wednesday_leading_padding_is_three() {
        // 2024-05-01 is Wednesday → Sun..Tue が前月余白
        let days = MonthGridGeometry.grid(for: date(year: 2024, month: 5), calendar: calendar)
        let leadingPadding = days.prefix(while: { !$0.isInMonth }).count
        #expect(leadingPadding == 3)
    }

    @Test
    func days_are_in_chronological_order() {
        let days = MonthGridGeometry.grid(for: date(year: 2024, month: 7), calendar: calendar)
        let dates = days.map(\.date)
        #expect(dates == dates.sorted())
    }
}
