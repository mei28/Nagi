import Foundation

/// `CircularTimerView` への入力となる軽量な状態 enum。
///
/// `TimerEngine.State` は `Session` を持つので View には大き過ぎる。
/// 描画用に最小情報だけを抽出した型。
enum TimerVisualState: Equatable, Hashable, CaseIterable {
    case idle
    case working
    case pendingBreak
    case onBreak
}

extension TimerVisualState {
    /// `TimerEngine.State` から導出する変換。
    @MainActor
    init(_ engineState: TimerEngine.State) {
        switch engineState {
        case .idle: self = .idle
        case .working: self = .working
        case .pendingBreak: self = .pendingBreak
        case .onBreak: self = .onBreak
        }
    }
}
