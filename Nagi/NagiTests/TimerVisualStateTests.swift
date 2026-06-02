import Testing
import Foundation
@testable import Nagi

@MainActor
struct TimerVisualStateTests {

    @Test
    func maps_idle_engine_state() {
        #expect(TimerVisualState(TimerEngine.State.idle) == .idle)
    }

    @Test
    func maps_working_engine_state() throws {
        let now = Date()
        let session = Session(startTime: now, createdAt: now, updatedAt: now)
        #expect(TimerVisualState(TimerEngine.State.working(session)) == .working)
    }

    @Test
    func maps_pendingBreak_engine_state() {
        let now = Date()
        let session = Session(startTime: now, createdAt: now, updatedAt: now)
        #expect(TimerVisualState(TimerEngine.State.pendingBreak(session, suggestedDuration: 120)) == .pendingBreak)
    }

    @Test
    func maps_onBreak_engine_state() {
        let info = TimerEngine.BreakInfo(startTime: Date(), plannedDuration: 120)
        #expect(TimerVisualState(TimerEngine.State.onBreak(info)) == .onBreak)
    }

    @Test
    func has_four_distinct_cases() {
        #expect(TimerVisualState.allCases.count == 4)
    }
}
