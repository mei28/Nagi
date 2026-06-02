import Foundation

/// 現在時刻を提供する抽象。テストでは固定値を返す実装に差し替える。
///
/// Rust の所有権と違って Swift では `Date.now` がグローバル関数のように使えるので、
/// テスト時の固定時刻注入のために薄くラップするだけのプロトコル。
protocol Clock: Sendable {
    var now: Date { get }
}

/// 実時刻を返す既定実装。
struct SystemClock: Clock {
    var now: Date { Date() }
}
