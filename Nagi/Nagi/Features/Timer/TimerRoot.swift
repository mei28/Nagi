import SwiftUI
import SwiftData

/// Timer タブのルート。`TimerEngine.state` でサブ画面を切り替える。
///
/// `ContentView` で `TabView` 化したため、Timer 全体を 1 つの View にまとめる必要が出た。
/// Repository は親から受け取らず、ここで `ModelContext` から作る (TabView ごとに 1 つで OK)。
struct TimerRoot: View {
    @Bindable var engine: TimerEngine
    @Environment(\.modelContext) private var modelContext

    @State private var repository: SwiftDataSessionRepository?
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    var body: some View {
        Group {
            if let repository {
                routed(repository: repository)
            } else {
                ProgressView()
                    .frame(minWidth: 480, minHeight: 640)
            }
        }
        .task {
            if repository == nil {
                repository = SwiftDataSessionRepository(context: modelContext)
            }
        }
    }

    @ViewBuilder
    private func routed(repository: SwiftDataSessionRepository) -> some View {
        switch engine.state {
        case .idle, .working:
            MainView(engine: engine, repository: repository)
        case .pendingBreak:
            PendingBreakView(
                engine: engine,
                onStartBreak: { duration in
                    do {
                        _ = try engine.confirmBreak(duration: duration)
                        if notificationEnabled {
                            Task {
                                try? await NotificationService.shared
                                    .scheduleBreakEnd(after: duration, playSound: soundEnabled)
                            }
                        }
                    } catch {
                        print("confirmBreak failed: \(error)")
                    }
                },
                onSkip: {
                    try? engine.skipBreak()
                }
            )
        case .onBreak:
            BreakCountdownView(engine: engine) {
                NotificationService.shared.cancelBreakEnd()
                try? engine.endBreak()
            }
        }
    }
}
