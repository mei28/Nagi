import SwiftUI
import SwiftData

/// 設定タブ。タイマー設定 / 通知 / 言語 / データ操作 (Export, Import, 全削除) を集約。
///
/// 個別の値は `@AppStorage` で UserDefaults に永続化。Preferences struct (Codable) は
/// Export/Import 時のスナップショットとして組み立てる。
struct PreferencesView: View {
    @Query private var sessions: [Session]
    @Environment(\.modelContext) private var modelContext

    @AppStorage("rotationMinutes") private var rotationMinutes: Int = 30
    @AppStorage("breakRatio") private var breakRatio: Double = 0.20
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("language") private var language: String = "system"

    @State private var showingImportDecision = false
    @State private var pendingImport: ExportData?
    @State private var showingDeleteAllConfirm = false
    @State private var deleteAllStage: DeleteStage = .none

    enum DeleteStage {
        case none
        case firstConfirm  // 「本当に消す?」
        case secondConfirm // 「最終確認」
    }

    var body: some View {
        Form {
            timerSection
            notificationsSection
            languageSection
            dataSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 460)
        .confirmationDialog(
            "Replace or merge?",
            isPresented: $showingImportDecision,
            titleVisibility: .visible,
            presenting: pendingImport
        ) { data in
            Button("Replace existing") { applyImport(data, strategy: .replace) }
            Button("Merge") { applyImport(data, strategy: .merge) }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: { data in
            Text("Found \(data.sessions.count) sessions. Replace deletes existing data; Merge keeps existing on timestamp conflicts.")
        }
        .confirmationDialog(
            deleteAllStage == .firstConfirm ? "Delete all sessions?" : "This cannot be undone. Really delete?",
            isPresented: $showingDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            switch deleteAllStage {
            case .firstConfirm:
                Button("Continue", role: .destructive) {
                    deleteAllStage = .secondConfirm
                    showingDeleteAllConfirm = true
                }
                Button("Cancel", role: .cancel) {
                    deleteAllStage = .none
                }
            case .secondConfirm:
                Button("Delete all", role: .destructive) {
                    deleteAllSessions()
                    deleteAllStage = .none
                }
                Button("Cancel", role: .cancel) {
                    deleteAllStage = .none
                }
            case .none:
                EmptyView()
            }
        } message: {
            switch deleteAllStage {
            case .firstConfirm:
                Text("This will permanently delete all \(sessions.count) sessions.")
            case .secondConfirm:
                Text("Final confirmation. This action cannot be undone.")
            case .none:
                EmptyView()
            }
        }
    }

    // MARK: - Sections

    private var timerSection: some View {
        Section("Timer") {
            Picker("Rotation", selection: $rotationMinutes) {
                Text("1 min").tag(1)
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("60 min").tag(60)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text("Break ratio")
                    Spacer()
                    Text("\(Int((breakRatio * 100).rounded()))%")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $breakRatio, in: 0.01...1.00, step: 0.01)
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Notification", isOn: $notificationEnabled)
            Toggle("Sound", isOn: $soundEnabled)
                .disabled(!notificationEnabled)
        }
    }

    private var languageSection: some View {
        Section {
            Picker("Language", selection: $language) {
                Text("System").tag("system")
                Text("日本語").tag("ja")
                Text("English").tag("en")
            }
            Text("Restart the app to fully apply the language change.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Language")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Export…", action: exportData)
            Button("Import…", action: importData)
            Button("Delete all sessions", role: .destructive) {
                deleteAllStage = .firstConfirm
                showingDeleteAllConfirm = true
            }
        }
    }

    // MARK: - Handlers

    private func exportData() {
        let prefs = currentPreferences()
        ExportImportService.runExport(sessions: sessions, preferences: prefs)
    }

    private func importData() {
        guard let data = ExportImportService.runImport() else { return }
        pendingImport = data
        showingImportDecision = true
    }

    private func applyImport(_ data: ExportData, strategy: ImportStrategy) {
        switch strategy {
        case .replace:
            for session in sessions {
                modelContext.delete(session)
            }
        case .merge:
            break
        }

        let existingIDs = Set(sessions.map(\.id))
        for dto in data.sessions {
            if strategy == .merge, existingIDs.contains(dto.id) { continue }
            modelContext.insert(dto.toSession())
        }

        rotationMinutes = data.settings.rotationMinutes
        breakRatio = data.settings.breakRatio
        notificationEnabled = data.settings.notificationEnabled
        soundEnabled = data.settings.soundEnabled
        language = data.settings.language

        try? modelContext.save()
        pendingImport = nil
    }

    private func deleteAllSessions() {
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    private func currentPreferences() -> Preferences {
        Preferences(
            breakRatio: breakRatio,
            rotationMinutes: rotationMinutes,
            notificationEnabled: notificationEnabled,
            soundEnabled: soundEnabled,
            language: language
        )
    }

    private enum ImportStrategy {
        case replace, merge
    }
}
