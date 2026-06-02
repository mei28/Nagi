import SwiftUI
import SwiftData

@main
struct NagiApp: App {
    /// TimerEngine は App レベルで保持して WindowGroup と MenuBarExtra で共有する。
    @State private var engine = TimerEngine()

    init() {
        Task { @MainActor in
            await NotificationService.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(engine: engine)
        }
        .modelContainer(for: Session.self)

        MenuBarExtra {
            TimerMenuBarContent(engine: engine)
                .modelContainer(for: Session.self)
        } label: {
            menuBarIcon
        }
        .menuBarExtraStyle(.window)
    }

    /// メニューバーラベル。
    ///
    /// Asset Catalog の Image Set (template rendering) を使うので menu bar が
    /// black/white に auto-tint する。形は別 Claude セッションが作った独自シンボル:
    /// - idle:         outline の円 (Nagi らしい円、待機)
    /// - working:      塗りつぶしの円 (active)
    /// - pendingBreak: outline の三日月 (休憩に向かう)
    /// - onBreak:      塗りつぶしの三日月 (完全な休息)
    @ViewBuilder
    private var menuBarIcon: some View {
        Image(menuBarSymbol)
            .accessibilityLabel(menuBarAccessibilityLabel)
    }

    private var menuBarSymbol: String {
        switch engine.state {
        case .idle: "nagi.menubar.idle"
        case .working: "nagi.menubar.working"
        case .pendingBreak: "nagi.menubar.pendingBreak"
        case .onBreak: "nagi.menubar.onBreak"
        }
    }

    private var menuBarAccessibilityLabel: String {
        switch engine.state {
        case .idle: String(localized: "Nagi — idle")
        case .working: String(localized: "Nagi — working")
        case .pendingBreak: String(localized: "Nagi — suggested break")
        case .onBreak: String(localized: "Nagi — on break")
        }
    }
}
