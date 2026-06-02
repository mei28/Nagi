import SwiftUI
import SwiftData
import AppKit

/// メニューバー (MenuBarExtra) から呼ばれるポップアップ。
///
/// 上部に Segmented Picker で Timer / Calendar / History を切替、
/// 下部に「Open Nagi…」「Quit」を配置。Glass トーンは `.regularMaterial`
/// 背景 + 角丸 + 影で実現 (macOS 14+ 互換)。
struct TimerMenuBarContent: View {
    @Bindable var engine: TimerEngine
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @AppStorage("breakRatio") private var breakRatio: Double = 0.20
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    @State private var section: MenuSection = .timer
    @State private var repository: SwiftDataSessionRepository?

    enum MenuSection: String, CaseIterable, Identifiable {
        case timer, calendar, history
        var id: String { rawValue }

        var label: String {
            switch self {
            case .timer: String(localized: "Timer")
            case .calendar: String(localized: "Calendar")
            case .history: String(localized: "History")
            }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            sectionPicker
            sectionContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .liquidGlassCard()
            menuItems
                .padding(.horizontal, 4)
        }
        .padding(16)
        .frame(width: 320)
        .liquidGlassBackground()
        .task {
            if repository == nil {
                repository = SwiftDataSessionRepository(context: modelContext)
            }
        }
    }

    private var sectionPicker: some View {
        Picker("", selection: $section) {
            ForEach(MenuSection.allCases) { sect in
                Text(sect.label).tag(sect)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .timer: timerSection
        case .calendar: CalendarMiniView()
        case .history: HistoryMiniView()
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 12) {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                statusBlock
            }
            primaryButton
        }
    }

    private var statusBlock: some View {
        VStack(spacing: 6) {
            Text(statusLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(displayTime)
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .monospacedDigit()
        }
    }

    private var statusLabel: String {
        switch engine.state {
        case .idle: String(localized: "Idle")
        case .working: String(localized: "Working")
        case .pendingBreak: String(localized: "suggested break")
        case .onBreak: String(localized: "On break")
        }
    }

    private var displayTime: String {
        switch engine.state {
        case .idle:
            return "00:00"
        case .working:
            return formatHMS(engine.elapsed)
        case .pendingBreak:
            return formatHMS(engine.suggestedBreakDuration ?? 0)
        case .onBreak(let info):
            let remaining = max(0, info.plannedDuration - engine.elapsed)
            return formatHMS(remaining)
        }
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch engine.state {
        case .idle:
            Button(action: startSession) {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        case .working:
            Button(action: stopSession) {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.red)
        case .pendingBreak:
            HStack(spacing: 8) {
                Button("Skip", action: skipBreak)
                    .controlSize(.large)
                    .buttonStyle(.bordered)
                Button(action: confirmBreak) {
                    Label("Start break", systemImage: "cup.and.saucer.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        case .onBreak:
            Button(action: endBreak) {
                Label("End break", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    // MARK: - Menu Items

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                openMainWindow()
            } label: {
                Label("Open Nagi…", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit Nagi", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
    }

    /// フルウィンドウを開く。
    ///
    /// 常駐中は `.accessory` (Dock 非表示) なので、ウィンドウを出す間だけ
    /// `.regular` にして標準メニューバーとフォーカスを得る。閉じると
    /// [`AppDelegate`] が `.accessory` に戻す。
    private func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: WindowID.main)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Actions

    private func startSession() {
        guard let repository else { return }
        do {
            let session = try engine.start()
            Task { try await repository.create(session) }
        } catch {
            print("menu start failed: \(error)")
        }
    }

    private func stopSession() {
        guard let repository else { return }
        do {
            let session = try engine.stop(breakRatio: breakRatio)
            Task { try await repository.update(session) }
        } catch {
            print("menu stop failed: \(error)")
        }
    }

    private func confirmBreak() {
        guard let suggested = engine.suggestedBreakDuration else { return }
        do {
            _ = try engine.confirmBreak(duration: suggested)
            if notificationEnabled {
                Task {
                    try? await NotificationService.shared
                        .scheduleBreakEnd(after: suggested, playSound: soundEnabled)
                }
            }
        } catch {
            print("menu confirmBreak failed: \(error)")
        }
    }

    private func skipBreak() {
        try? engine.skipBreak()
    }

    private func endBreak() {
        NotificationService.shared.cancelBreakEnd()
        try? engine.endBreak()
    }

    // MARK: - Formatting

    private func formatHMS(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
