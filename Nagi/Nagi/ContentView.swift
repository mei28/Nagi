import SwiftUI
import SwiftData

/// アプリのトップレベル View。
///
/// Timer / History の 2 タブ構成。`TimerEngine` は ContentView レベルで保持し、
/// Tab 切替でもタイマーが裏で進行し続けるようにする。
/// Phase 6 で Calendar、Phase 7 で Settings タブを追加予定。
struct ContentView: View {
    @Bindable var engine: TimerEngine

    var body: some View {
        TabView {
            TimerRoot(engine: engine)
                .tabItem { Label("Timer", systemImage: "timer") }

            CalendarScreen()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            HistoryScreen()
                .tabItem { Label("History", systemImage: "list.bullet") }

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .frame(minWidth: 520, minHeight: 680)
    }
}

#Preview {
    ContentView(engine: TimerEngine())
        .modelContainer(for: Session.self, inMemory: true)
}
