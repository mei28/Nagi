import SwiftUI
import Combine

/// 休憩中の画面 (砂時計式)。
///
/// 扇形の長さは「残り時間 / plannedDuration」で算出する。
/// 開始時に円全体を埋め、時間経過で時計回りに短くなって 0 で消える。
/// 残り 0 で自動的に `onEnd` を呼び、通知 + サウンドを発火させる
/// (通知本体は `NotificationService.scheduleBreakEnd` で予約済み)。
struct BreakCountdownView: View {
    @Bindable var engine: TimerEngine
    let onEnd: () -> Void

    private let tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            let planned = engine.currentBreakInfo?.plannedDuration ?? 0
            let elapsed = engine.elapsed
            let remaining = max(0, planned - elapsed)

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    CircularTimerView(
                        state: .onBreak,
                        elapsed: remaining,
                        rotationSeconds: planned > 0 ? planned : 60
                    )
                    .frame(width: 280, height: 280)

                    Text(formatRemaining(remaining))
                        .font(.system(size: 36, weight: .light, design: .monospaced))
                        .monospacedDigit()
                    Text("remaining")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Button("End break") {
                    onEnd()
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(40)
            .frame(minWidth: 480, minHeight: 640)
        }
        .onReceive(tick) { _ in
            guard let info = engine.currentBreakInfo else { return }
            if engine.elapsed >= info.plannedDuration {
                onEnd()
            }
        }
    }

    private func formatRemaining(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
