import SwiftUI

/// 「このアプリについて」タブ。
///
/// バージョン情報と簡単な説明、ライセンスを表示する。
struct AboutView: View {
    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Divider()

                section(title: "About") {
                    Text("Nagi is a flow-time work-session tracker for macOS. Work in your own rhythm and let Nagi suggest a break proportional to how long you focused.")
                }

                section(title: "How to use") {
                    bullet("Press Start when you begin focusing.")
                    bullet("Press Stop when you finish — Nagi suggests a break (work × break ratio).")
                    bullet("Take the break or skip it. The countdown drains like an hourglass.")
                    bullet("Use the Calendar to see your daily workload at a glance.")
                    bullet("Edit notes or remove past sessions from the History tab.")
                }

                section(title: "License") {
                    Text("MIT License. Source available on GitHub.")
                }
            }
            .padding(32)
            .frame(maxWidth: 560, alignment: .leading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nagi")
                .font(.largeTitle.weight(.semibold))
            Text("Version \(versionString)")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(.secondary)
            Text(text)
        }
    }
}
