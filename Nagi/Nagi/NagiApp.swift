import SwiftUI
import SwiftData
import AppKit

/// メニューバー常駐アプリ。Dock アイコンは出さず、フルウィンドウは
/// メニューバーの「Open Nagi…」から開く ([`AppDelegate`] が制御)。
@main
struct NagiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// TimerEngine は App レベルで保持して Window と MenuBarExtra で共有する。
    @State private var engine = TimerEngine()

    /// SwiftData コンテナは 1 つだけ生成して全シーンで共有する。
    /// シーンごとに `.modelContainer(for:)` を付けると別インスタンスになり、
    /// 片方の変更がもう片方の `@Query` にライブ反映されない。
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: Session.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    init() {
        // Dock アイコンと標準メニューを出さないメニューバー常駐アプリにする。
        // init で設定することで起動時の Dock アイコン点滅を抑える。
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // フルウィンドウ (単一インスタンス)。起動時は AppDelegate が閉じ、
        // 「Open Nagi…」で openWindow(id:) から開く。
        Window("Nagi", id: WindowID.main) {
            ContentView(engine: engine)
        }
        .modelContainer(container)

        MenuBarExtra {
            TimerMenuBarContent(engine: engine)
                .modelContainer(container)
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

/// SwiftUI シーンの識別子。
enum WindowID {
    static let main = "main"
}
