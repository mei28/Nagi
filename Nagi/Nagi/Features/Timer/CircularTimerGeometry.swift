import Foundation

/// 円形タイマー描画のための算術。
///
/// `Canvas` から呼ぶ計算をテスタブルにするために pure な関数として切り出す。
/// 描画そのもの (扇形のパス組み立て / 角度) はここでは扱わない。
enum CircularTimerGeometry {

    /// 現在の周回番号 (1-origin)。
    ///
    /// - elapsed=0 → 1 (1 周目開始)
    /// - elapsed=rotationSeconds → 2 (2 周目に入った瞬間)
    /// - rotationSeconds <= 0 のときは 1 を返す (描画側のフォールバック想定)
    static func currentRotation(
        elapsed: TimeInterval,
        rotationSeconds: TimeInterval
    ) -> Int {
        guard rotationSeconds > 0, elapsed > 0 else { return 1 }
        return Int(elapsed / rotationSeconds) + 1
    }

    /// 現在の周回内での進捗 (0.0 ..< 1.0)。
    ///
    /// elapsed が rotationSeconds の倍数の瞬間は 0.0 (次の周回の開始扱い)。
    static func progressInCurrentRotation(
        elapsed: TimeInterval,
        rotationSeconds: TimeInterval
    ) -> Double {
        guard rotationSeconds > 0 else { return 0 }
        let remainder = elapsed.truncatingRemainder(dividingBy: rotationSeconds)
        return remainder / rotationSeconds
    }

    /// 完了した周回数 (= 360° 描き終わった扇形の本数)。
    ///
    /// - elapsed < rotationSeconds → 0
    /// - elapsed == rotationSeconds → 1
    static func completedRotations(
        elapsed: TimeInterval,
        rotationSeconds: TimeInterval
    ) -> Int {
        guard rotationSeconds > 0, elapsed > 0 else { return 0 }
        return Int(elapsed / rotationSeconds)
    }
}
