import SwiftUI

/// メイン画面 (idle / working)。
///
/// `TimelineView` で 10Hz 駆動して `CircularTimerView` をライブ更新する。
/// Stop は sheet を出さず、`TimerEngine.stop(breakRatio:)` を呼ぶだけ。
/// 状態遷移 (pendingBreak への切替) は `ContentView` 側のルーティングが担う。
/// セッションのメモは後から `HistoryView` で編集する設計 (Phase 5 で実装)。
struct MainView: View {
    @Bindable var engine: TimerEngine
    let repository: any SessionRepository

    @AppStorage("breakRatio") private var breakRatio: Double = 0.20
    @AppStorage("rotationMinutes") private var rotationMinutes: Int = 30

    private var rotationSeconds: TimeInterval { TimeInterval(rotationMinutes * 60) }

    var body: some View {
        VStack(spacing: 32) {
            TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                VStack(spacing: 12) {
                    CircularTimerView(
                        state: TimerVisualState(engine.state),
                        elapsed: engine.elapsed,
                        rotationSeconds: rotationSeconds
                    )
                    .frame(width: 280, height: 280)

                    Text(formatElapsed(engine.elapsed))
                        .font(.system(size: 36, weight: .light, design: .monospaced))
                        .monospacedDigit()
                }
            }

            Button(action: handleTap) {
                Text(buttonLabel)
                    .frame(minWidth: 140)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(buttonTint)
            .accessibilityLabel(buttonLabel)
            .accessibilityHint(buttonAccessibilityHint)
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 640)
    }

    private var buttonAccessibilityHint: String {
        switch engine.state {
        case .idle: String(localized: "Starts a new work session.")
        case .working: String(localized: "Stops the current session and proposes a break.")
        default: ""
        }
    }

    private var buttonLabel: String {
        switch engine.state {
        case .idle: String(localized: "Start")
        case .working: String(localized: "Stop")
        default: ""
        }
    }

    private var buttonTint: Color {
        switch engine.state {
        case .idle: .blue
        case .working: .red
        default: .gray
        }
    }

    private func handleTap() {
        switch engine.state {
        case .idle: startSession()
        case .working: stopSession()
        default: break
        }
    }

    private func startSession() {
        do {
            let session = try engine.start()
            Task { try await repository.create(session) }
        } catch {
            print("start failed: \(error)")
        }
    }

    private func stopSession() {
        do {
            let session = try engine.stop(breakRatio: breakRatio)
            Task { try await repository.update(session) }
        } catch {
            print("stop failed: \(error)")
        }
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
