import SwiftUI

/// 設定タブのルート。「設定」と「このアプリについて」の 2 段サブタブで切り替える。
struct SettingsScreen: View {
    var body: some View {
        TabView {
            PreferencesView()
                .tabItem { Label("Settings", systemImage: "gear") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(.top, 8)
    }
}
