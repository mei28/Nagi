import Testing
import Foundation
@testable import Nagi

struct ClockTests {

    @Test
    func systemClock_returns_current_time() {
        let before = Date()
        let now = SystemClock().now
        let after = Date()

        #expect(now >= before)
        #expect(now <= after)
    }

    @Test
    func fixedClock_returns_initial_value() {
        let t = Date(timeIntervalSince1970: 1_000)
        let clock = FixedClock(t)
        #expect(clock.now == t)
    }

    @Test
    func fixedClock_advance_moves_now_forward() {
        let t = Date(timeIntervalSince1970: 1_000)
        let clock = FixedClock(t)
        clock.advance(by: 60)
        #expect(clock.now == t.addingTimeInterval(60))
    }

    @Test
    func fixedClock_advance_accepts_negative_for_rewind() {
        let t = Date(timeIntervalSince1970: 1_000)
        let clock = FixedClock(t)
        clock.advance(by: -10)
        #expect(clock.now == t.addingTimeInterval(-10))
    }
}
