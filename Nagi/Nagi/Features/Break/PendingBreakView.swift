import SwiftUI

/// 作業停止直後の休憩提案画面 (Fathom の `pending_break` 状態に相当)。
///
/// 提案時間は `TimerEngine` が `stop(breakRatio:)` で算出した値をそのまま使う。
/// ユーザー操作は Start break / Skip の 2 択のみ (Fathom 準拠)。
/// セッションのメモはここでは入力させず、後から `HistoryView` で編集する。
struct PendingBreakView: View {
    @Bindable var engine: TimerEngine
    let onStartBreak: (_ duration: TimeInterval) -> Void
    let onSkip: () -> Void

    var body: some View {
        let breakSeconds = engine.suggestedBreakDuration ?? 0

        VStack(spacing: 32) {
            CircularTimerView(
                state: .pendingBreak,
                elapsed: breakSeconds,
                rotationSeconds: max(60, breakSeconds)
            )
            .frame(width: 280, height: 280)

            VStack(spacing: 4) {
                Text(formatDuration(breakSeconds))
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .monospacedDigit()
                Text("suggested break")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button {
                    onStartBreak(breakSeconds)
                } label: {
                    Text("Start break")
                        .frame(minWidth: 160)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(breakSeconds <= 0)

                Button("Skip", action: onSkip)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 640)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
