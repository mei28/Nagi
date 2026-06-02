import SwiftUI
import SwiftData

/// メニューバー用の簡易履歴。
///
/// メニューバーでは「メモを書き換える」「削除する」だけに機能を絞る。
/// セッションの時刻変更や追加はメインウィンドウの History タブで行う。
struct HistoryMiniView: View {
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent sessions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(sessions.prefix(5)), id: \.id) { session in
                        HistoryMiniRow(
                            session: session,
                            onDelete: { delete(session) }
                        )
                    }
                }
            }
        }
    }

    private func delete(_ session: Session) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}

/// 1 行ぶんの簡易表示 + メモ inline 編集 + 削除。
struct HistoryMiniRow: View {
    @Bindable var session: Session
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @FocusState private var noteFocused: Bool
    @State private var noteDraft: String = ""

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            noteField
        }
        .padding(8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 6))
    }

    private var header: some View {
        HStack {
            Text(timeRange)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Spacer()
            Text(durationText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(String(localized: "Delete"))
        }
    }

    private var noteField: some View {
        TextField(
            String(localized: "Add note…"),
            text: $noteDraft,
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .font(.callout)
        .lineLimit(1...3)
        .focused($noteFocused)
        .onAppear { noteDraft = session.note ?? "" }
        .onChange(of: noteFocused) { _, focused in
            if !focused { commit() }
        }
        .onSubmit { commit() }
    }

    private var timeRange: String {
        let start = Self.timeFormatter.string(from: session.startTime)
        if let end = session.endTime {
            return "\(start) – \(Self.timeFormatter.string(from: end))"
        }
        return "\(start) – …"
    }

    private var durationText: String {
        guard let duration = session.duration else { return String(localized: "in progress") }
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func commit() {
        let trimmed = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue: String? = trimmed.isEmpty ? nil : trimmed
        guard newValue != session.note else { return }
        session.note = newValue
        session.updatedAt = Date()
        try? modelContext.save()
    }
}
