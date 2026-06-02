import SwiftUI

/// Time Timer 風の円形タイマー View。
///
/// 入力は静的: 状態 (外枠色用)、経過秒数、1 周の秒数。
/// 時間経過を反映させたい場合は外側で `TimelineView` をラップし、
/// `context.date` から経過秒を計算して渡す。Phase 4 で導入予定。
///
/// 描画仕様 (SPEC FR-5):
/// - 12 時位置から時計回りに扇形が伸びる
/// - 完了した周回は薄く塗り残し、現在の周回は濃い色で塗る
/// - 周回ごとに色が変わる (青 → インディゴ → 紫 → パープル)
/// - 外枠色で状態を示す (グレー: idle / 青: working / 緑: break)
struct CircularTimerView: View {
    let state: TimerVisualState
    let elapsed: TimeInterval
    let rotationSeconds: TimeInterval

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - inset
            let completed = CircularTimerGeometry.completedRotations(
                elapsed: elapsed, rotationSeconds: rotationSeconds
            )
            let progress = CircularTimerGeometry.progressInCurrentRotation(
                elapsed: elapsed, rotationSeconds: rotationSeconds
            )

            // 完了周回ぶんの扇形。
            // - working: 周回色 (青→インディゴ→紫→パープル) を薄く残す
            // - onBreak: 周回色 (深緑→緑→ミント→ライム) を薄く残す
            // - pendingBreak: 1 周以下なので completed は通常 0
            // - idle:    completed が 0 なので実質スキップ
            for i in 0..<completed {
                let color: Color = switch state {
                case .working: Theme.rotationColor(at: i).opacity(Theme.completedRotationOpacity)
                case .onBreak, .pendingBreak: Theme.breakRotationColor(at: i).opacity(Theme.completedRotationOpacity)
                case .idle: .clear
                }
                ctx.fill(
                    fanPath(center: center, radius: radius, fraction: 1.0),
                    with: .color(color)
                )
            }

            // 現在の周回の扇形。
            // - working: 周回色 (青→インディゴ→紫→パープル)
            // - onBreak / pendingBreak: 周回色 (深緑→緑→ミント→ライム)
            // - idle:    描画しない
            if state != .idle, progress > 0 {
                let color: Color = switch state {
                case .working: Theme.rotationColor(at: completed)
                case .onBreak, .pendingBreak: Theme.breakRotationColor(at: completed)
                case .idle: .clear  // 上の guard で除外済み
                }
                ctx.fill(
                    fanPath(center: center, radius: radius, fraction: progress),
                    with: .color(color)
                )
            }

            // 外枠は常に状態色で描画。
            var outline = Path()
            outline.addArc(
                center: center, radius: radius,
                startAngle: .zero, endAngle: .degrees(360),
                clockwise: false
            )
            ctx.stroke(
                outline,
                with: .color(Theme.accent(for: state)),
                lineWidth: outlineWidth
            )

            // 針は idle 以外で表示。
            if state != .idle {
                let needleEnd = needlePoint(center: center, radius: radius, fraction: progress)
                var needle = Path()
                needle.move(to: center)
                needle.addLine(to: needleEnd)
                ctx.stroke(needle, with: .color(.primary), lineWidth: needleWidth)
            }
        }
    }

    // MARK: - 描画パラメータ

    private let inset: CGFloat = 12
    private let outlineWidth: CGFloat = 4
    private let needleWidth: CGFloat = 2

    // MARK: - パス組み立て

    /// 12 時位置から時計回りに `fraction` (0..1) ぶんの扇形を返す。
    ///
    /// SwiftUI の y 軸は下向き。`addArc(clockwise: false)` は数学的な反時計回り
    /// (= 画面上は時計回り) になる。
    private func fanPath(center: CGPoint, radius: CGFloat, fraction: Double) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * fraction),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }

    private func needlePoint(center: CGPoint, radius: CGFloat, fraction: Double) -> CGPoint {
        let angle = -CGFloat.pi / 2 + CGFloat(fraction) * 2 * .pi
        return CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }
}

#Preview("Working - 1 周目 25%") {
    CircularTimerView(state: .working, elapsed: 450, rotationSeconds: 1_800)
        .frame(width: 280, height: 280)
        .padding()
}

#Preview("Working - 2 周目 50%") {
    CircularTimerView(state: .working, elapsed: 1_800 + 900, rotationSeconds: 1_800)
        .frame(width: 280, height: 280)
        .padding()
}

#Preview("Break") {
    CircularTimerView(state: .onBreak, elapsed: 60, rotationSeconds: 120)
        .frame(width: 280, height: 280)
        .padding()
}

#Preview("Idle") {
    CircularTimerView(state: .idle, elapsed: 0, rotationSeconds: 1_800)
        .frame(width: 280, height: 280)
        .padding()
}
