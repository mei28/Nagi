import Testing
import Foundation
@testable import Nagi

struct CalendarHeatmapColorTests {

    @Test
    func zero_minutes_is_level_zero() {
        #expect(CalendarHeatmapColor.level(forMinutes: 0) == 0)
    }

    @Test
    func one_minute_is_level_one() {
        #expect(CalendarHeatmapColor.level(forMinutes: 1) == 1)
    }

    @Test
    func fifty_nine_minutes_is_level_one() {
        #expect(CalendarHeatmapColor.level(forMinutes: 59) == 1)
    }

    @Test
    func sixty_minutes_is_level_two() {
        #expect(CalendarHeatmapColor.level(forMinutes: 60) == 2)
    }

    @Test
    func one_hundred_seventy_nine_minutes_is_level_two() {
        #expect(CalendarHeatmapColor.level(forMinutes: 179) == 2)
    }

    @Test
    func three_hours_is_level_three() {
        #expect(CalendarHeatmapColor.level(forMinutes: 180) == 3)
    }

    @Test
    func five_hours_is_level_four() {
        #expect(CalendarHeatmapColor.level(forMinutes: 300) == 4)
    }

    @Test
    func huge_value_is_capped_at_level_four() {
        #expect(CalendarHeatmapColor.level(forMinutes: 9999) == 4)
    }
}
