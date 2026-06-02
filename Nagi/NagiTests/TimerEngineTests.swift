import Testing
import Foundation
@testable import Nagi

@MainActor
struct TimerEngineTests {

    private func makeEngine(at t: Date = Date(timeIntervalSince1970: 1_000))
        -> (TimerEngine, FixedClock)
    {
        let clock = FixedClock(t)
        return (TimerEngine(clock: clock), clock)
    }

    // MARK: - 初期状態

    @Test
    func initial_state_is_idle() {
        let (engine, _) = makeEngine()
        #expect(isIdle(engine.state))
        #expect(engine.elapsed == 0)
        #expect(engine.activeSession == nil)
        #expect(engine.pendingBreakSession == nil)
        #expect(engine.currentBreakInfo == nil)
    }

    // MARK: - start

    @Test
    func start_transitions_to_working_and_creates_session_at_now() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, _) = makeEngine(at: t0)

        let session = try engine.start()

        #expect(session.startTime == t0)
        #expect(session.endTime == nil)
        #expect(session.createdAt == t0)
        #expect(engine.activeSession?.id == session.id)
    }

    @Test
    func start_from_working_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "start", from: "working")) {
            _ = try engine.start()
        }
    }

    @Test
    func start_from_onBreak_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        _ = try engine.confirmBreak(duration: 60)
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "start", from: "onBreak")) {
            _ = try engine.start()
        }
    }

    // MARK: - stop

    @Test
    func stop_transitions_to_pendingBreak_with_suggested_duration() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, clock) = makeEngine(at: t0)

        let session = try engine.start()
        clock.advance(by: 600)
        let stopped = try engine.stop(breakRatio: 0.2)

        #expect(stopped.id == session.id)
        #expect(stopped.endTime == t0.addingTimeInterval(600))
        #expect(stopped.duration == 600)
        #expect(engine.pendingBreakSession?.id == session.id)
        #expect(engine.suggestedBreakDuration == 120)
        #expect(engine.activeSession == nil)
    }

    @Test
    func stop_from_idle_throws() {
        let (engine, _) = makeEngine()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "stop", from: "idle")) {
            _ = try engine.stop(breakRatio: 0.2)
        }
    }

    @Test
    func stop_from_onBreak_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        _ = try engine.confirmBreak(duration: 60)
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "stop", from: "onBreak")) {
            _ = try engine.stop(breakRatio: 0.2)
        }
    }

    // MARK: - confirmBreak

    @Test
    func confirmBreak_transitions_to_onBreak_with_clock_startTime() throws {
        let t0 = Date(timeIntervalSince1970: 2_000)
        let (engine, clock) = makeEngine(at: t0)

        _ = try engine.start()
        clock.advance(by: 300)
        _ = try engine.stop(breakRatio: 0.2)

        clock.advance(by: 10)
        let info = try engine.confirmBreak(duration: 60)

        #expect(info.startTime == t0.addingTimeInterval(310))
        #expect(info.plannedDuration == 60)
        #expect(engine.currentBreakInfo?.plannedDuration == 60)
    }

    @Test
    func confirmBreak_from_working_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "confirmBreak", from: "working")) {
            _ = try engine.confirmBreak(duration: 60)
        }
    }

    @Test
    func confirmBreak_from_idle_throws() {
        let (engine, _) = makeEngine()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "confirmBreak", from: "idle")) {
            _ = try engine.confirmBreak(duration: 60)
        }
    }

    // MARK: - skipBreak

    @Test
    func skipBreak_from_pendingBreak_returns_to_idle() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)

        try engine.skipBreak()

        #expect(isIdle(engine.state))
        #expect(engine.pendingBreakSession == nil)
    }

    @Test
    func skipBreak_from_onBreak_returns_to_idle() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        _ = try engine.confirmBreak(duration: 60)

        try engine.skipBreak()

        #expect(isIdle(engine.state))
        #expect(engine.currentBreakInfo == nil)
    }

    @Test
    func skipBreak_from_idle_throws() {
        let (engine, _) = makeEngine()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "skipBreak", from: "idle")) {
            try engine.skipBreak()
        }
    }

    @Test
    func skipBreak_from_working_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "skipBreak", from: "working")) {
            try engine.skipBreak()
        }
    }

    // MARK: - endBreak

    @Test
    func endBreak_from_onBreak_returns_to_idle() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        _ = try engine.confirmBreak(duration: 60)

        try engine.endBreak()

        #expect(isIdle(engine.state))
        #expect(engine.currentBreakInfo == nil)
    }

    @Test
    func endBreak_from_pendingBreak_throws() throws {
        let (engine, _) = makeEngine()
        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        #expect(throws: TimerEngine.TransitionError.invalidTransition(action: "endBreak", from: "pendingBreak")) {
            try engine.endBreak()
        }
    }

    // MARK: - elapsed

    @Test
    func elapsed_during_working_is_clock_diff_from_session_start() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, clock) = makeEngine(at: t0)

        _ = try engine.start()
        clock.advance(by: 90)
        #expect(engine.elapsed == 90)
    }

    @Test
    func elapsed_during_pendingBreak_is_zero() throws {
        let (engine, clock) = makeEngine()
        _ = try engine.start()
        clock.advance(by: 600)
        _ = try engine.stop(breakRatio: 0.2)

        #expect(engine.elapsed == 0)
    }

    @Test
    func elapsed_during_onBreak_is_clock_diff_from_break_start() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, clock) = makeEngine(at: t0)

        _ = try engine.start()
        _ = try engine.stop(breakRatio: 0.2)
        _ = try engine.confirmBreak(duration: 60)
        clock.advance(by: 45)

        #expect(engine.elapsed == 45)
    }

    // MARK: - 統合シナリオ

    @Test
    func full_flow_work_propose_break_complete() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, clock) = makeEngine(at: t0)

        let session = try engine.start()
        clock.advance(by: 600)
        _ = try engine.stop(breakRatio: 0.2)

        #expect(engine.suggestedBreakDuration == 120)

        _ = try engine.confirmBreak(duration: 120)
        clock.advance(by: 120)
        try engine.endBreak()

        #expect(session.duration == 600)
        #expect(engine.activeSession == nil)
        #expect(engine.currentBreakInfo == nil)
        #expect(engine.elapsed == 0)
        #expect(isIdle(engine.state))
    }

    @Test
    func full_flow_work_skip_break() throws {
        let t0 = Date(timeIntervalSince1970: 1_000)
        let (engine, clock) = makeEngine(at: t0)

        _ = try engine.start()
        clock.advance(by: 600)
        _ = try engine.stop(breakRatio: 0.2)
        try engine.skipBreak()

        #expect(isIdle(engine.state))
    }

    // MARK: - Helpers

    private func isIdle(_ state: TimerEngine.State) -> Bool {
        if case .idle = state { true } else { false }
    }
}
