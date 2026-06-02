import Foundation
@testable import Nagi

/// テスト用に時間を固定/前進できる Clock。
///
/// 単に `now` を読み書きするだけのシンプルな class。並行アクセスは想定しない
/// (テストはほぼ単一スレッドで動かす)。
final class FixedClock: Clock, @unchecked Sendable {
    var now: Date

    init(_ now: Date) {
        self.now = now
    }

    /// 任意秒数だけ時計を進める。負値で巻き戻しも可能。
    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
