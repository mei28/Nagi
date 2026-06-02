import SwiftUI
import SwiftData

/// セッション追加 / 編集用のシート。
///
/// `endTime > startTime` のバリデーションを Save 押下前に行う。
/// 編集モードでは Delete ボタンが表示され、確認ダイアログ経由で削除する。
struct SessionEditorView: View {
    enum Mode {
        case add(initialDate: Date)
        case edit(Session)
    }

    let mode: Mode

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note: String
    @State private var showingDeleteConfirm = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add(let initialDate):
            let cal = Calendar.current
            let now = Date()
            var comps = cal.dateComponents([.year, .month, .day], from: initialDate)
            comps.hour = cal.component(.hour, from: now)
            comps.minute = 0
            let start = cal.date(from: comps) ?? initialDate
            _startTime = State(initialValue: start)
            _endTime = State(initialValue: start.addingTimeInterval(3_600))
            _note = State(initialValue: "")
        case .edit(let session):
            _startTime = State(initialValue: session.startTime)
            _endTime = State(initialValue: session.endTime ?? session.startTime.addingTimeInterval(3_600))
            _note = State(initialValue: session.note ?? "")
        }
    }

    private var isValid: Bool { endTime > startTime }

    private var isAddMode: Bool {
        if case .add = mode { true } else { false }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start", selection: $startTime)
                    DatePicker("End", selection: $endTime)
                    if !isValid {
                        Text("End time must be after start time.")
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                }
                Section("Note") {
                    TextField("What were you working on?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                if !isAddMode {
                    Section {
                        Button("Delete session", role: .destructive) {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isAddMode ? "New session" : "Edit session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Delete session?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteSession() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .frame(minWidth: 440, minHeight: 420)
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteValue: String? = trimmed.isEmpty ? nil : trimmed
        let now = Date()

        switch mode {
        case .add:
            let session = Session(
                startTime: startTime,
                endTime: endTime,
                note: noteValue,
                createdAt: now,
                updatedAt: now
            )
            modelContext.insert(session)
        case .edit(let session):
            session.startTime = startTime
            session.endTime = endTime
            session.note = noteValue
            session.updatedAt = now
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteSession() {
        if case .edit(let session) = mode {
            modelContext.delete(session)
            try? modelContext.save()
            dismiss()
        }
    }
}
