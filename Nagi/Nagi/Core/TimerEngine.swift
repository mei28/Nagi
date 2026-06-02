import Foundation
import Observation

/// アプリの中心となる状態機械。
///
/// View 層から独立して動作させたいので、ここには UI も Repository も含めない。
/// 状態の変化を観察するために `@Observable`、Session(@Model) を触るので `@MainActor`。
///
/// 遷移表 (Fathom フロー準拠):
/// ```
/// idle         --start-->                working
/// working      --stop(breakRatio)-->     pendingBreak (session.endTime 設定 + 提案時間算出)
/// pendingBreak --confirmBreak(duration)->onBreak
/// pendingBreak --skipBreak-->            idle
/// onBreak      --endBreak / 自動完了-->   idle
/// onBreak      --skipBreak-->            idle (手動早期終了)
/// ```
/// 上記以外の組み合わせは `TransitionError.invalidTransition` を投げる。
@MainActor
@Observable
final class TimerEngine {

    enum State {
        case idle
        case working(Session)
        case pendingBreak(Session, suggestedDuration: TimeInterval)
        /// `break` が Swift キーワードのため `onBreak`。
        case onBreak(BreakInfo)
    }

    struct BreakInfo: Equatable {
        let startTime: Date
        let plannedDuration: TimeInterval
    }

    enum TransitionError: Error, Equatable, CustomStringConvertible {
        case invalidTransition(action: String, from: String)

        var description: String {
            switch self {
            case .invalidTransition(let action, let from):
                "Cannot \(action) from .\(from)"
            }
        }
    }

    private(set) var state: State = .idle
    private let clock: any Clock

    init(clock: any Clock) {
        self.clock = clock
    }

    /// `SystemClock` を注入する既定イニシャライザ。
    /// デフォルト引数で `SystemClock()` を呼ぶと MainActor 隔離違反になるので
    /// convenience 経由で内部初期化する。
    convenience init() {
        self.init(clock: SystemClock())
    }

    // MARK: - 遷移

    @discardableResult
    func start() throws -> Session {
        guard case .idle = state else {
            throw TransitionError.invalidTransition(action: "start", from: stateName)
        }
        let now = clock.now
        let session = Session(startTime: now, createdAt: now, updatedAt: now)
        state = .working(session)
        return session
    }

    /// 作業を停止して `pendingBreak` 状態へ遷移する。
    /// `breakRatio` から休憩提案時間を算出して内部に保持する。
    @discardableResult
    func stop(breakRatio: Double) throws -> Session {
        guard case .working(let session) = state else {
            throw TransitionError.invalidTransition(action: "stop", from: stateName)
        }
        let now = clock.now
        session.endTime = now
        session.updatedAt = now
        let suggested = BreakCalculator.suggestedBreak(
            workDuration: session.duration ?? 0,
            ratio: breakRatio
        )
        state = .pendingBreak(session, suggestedDuration: suggested)
        return session
    }

    /// `pendingBreak` から `onBreak` へ。ユーザーが提案時間を調整した結果を渡す。
    @discardableResult
    func confirmBreak(duration: TimeInterval) throws -> BreakInfo {
        guard case .pendingBreak = state else {
            throw TransitionError.invalidTransition(action: "confirmBreak", from: stateName)
        }
        let info = BreakInfo(startTime: clock.now, plannedDuration: duration)
        state = .onBreak(info)
        return info
    }

    /// 休憩をスキップする。`pendingBreak` (提案時) と `onBreak` (進行中) の両方から idle へ。
    func skipBreak() throws {
        switch state {
        case .pendingBreak, .onBreak:
            state = .idle
        default:
            throw TransitionError.invalidTransition(action: "skipBreak", from: stateName)
        }
    }

    /// 休憩終了。自動完了 (残り 0) でも手動 (End break ボタン) でも呼ばれる。
    func endBreak() throws {
        guard case .onBreak = state else {
            throw TransitionError.invalidTransition(action: "endBreak", from: stateName)
        }
        state = .idle
    }

    // MARK: - 派生プロパティ

    /// 経過秒数。`Date` 差分で常に計算するので、裏に回って Timer が止まっても狂わない。
    var elapsed: TimeInterval {
        switch state {
        case .idle, .pendingBreak:
            0
        case .working(let session):
            clock.now.timeIntervalSince(session.startTime)
        case .onBreak(let info):
            clock.now.timeIntervalSince(info.startTime)
        }
    }

    var activeSession: Session? {
        if case .working(let session) = state { session } else { nil }
    }

    var pendingBreakSession: Session? {
        if case .pendingBreak(let session, _) = state { session } else { nil }
    }

    var suggestedBreakDuration: TimeInterval? {
        if case .pendingBreak(_, let suggested) = state { suggested } else { nil }
    }

    var currentBreakInfo: BreakInfo? {
        if case .onBreak(let info) = state { info } else { nil }
    }

    private var stateName: String {
        switch state {
        case .idle: "idle"
        case .working: "working"
        case .pendingBreak: "pendingBreak"
        case .onBreak: "onBreak"
        }
    }
}
