import Testing
import Foundation
@testable import Nagi

struct BreakCalculatorTests {

    @Test
    func zero_work_yields_zero_break() {
        let result = BreakCalculator.suggestedBreak(workDuration: 0, ratio: 0.20)
        #expect(result == 0)
    }

    @Test
    func default_ratio_20_percent_of_50_minutes_is_10_minutes() {
        let work: TimeInterval = 50 * 60
        let result = BreakCalculator.suggestedBreak(workDuration: work, ratio: 0.20)
        #expect(result == 10 * 60)
    }

    @Test
    func minimum_ratio_1_percent_of_600_seconds_is_6_seconds() {
        let result = BreakCalculator.suggestedBreak(workDuration: 600, ratio: 0.01)
        #expect(result == 6)
    }

    @Test
    func maximum_ratio_100_percent_returns_full_work_duration() {
        let result = BreakCalculator.suggestedBreak(workDuration: 300, ratio: 1.0)
        #expect(result == 300)
    }

    @Test
    func arbitrary_ratio_33_percent_of_30_minutes() {
        let work: TimeInterval = 30 * 60
        let result = BreakCalculator.suggestedBreak(workDuration: work, ratio: 0.33)
        #expect(result == 30 * 60 * 0.33)
    }
}
