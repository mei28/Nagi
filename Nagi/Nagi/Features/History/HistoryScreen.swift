import SwiftUI
import SwiftData

/// 履歴画面。
///
/// `@Query` で SwiftData を直接購読するので、Timer タブで Start/Stop した直後にも
/// 自動で反映される。Tab 切替で再生成されてもクエリの結果は維持される。
///
/// sheet の制御は `.sheet(item:)` パターンで `EditorPresentation?` を単一の state にする。
/// `.sheet(isPresented:)` + 別 state では item の反映タイミングと sheet 表示が
/// 噛み合わずに空 sheet が出るケースがあるため。
struct HistoryScreen: View {
    @Query(sort: \Session.startTime, order: .reverse) private var sessions: [Session]
    @Environment(\.modelContext) private var modelContext

    @State private var editor: EditorPresentation?
    @State private var pendingDelete: Session?
    @State private var showingDeleteConfirm = false

    /// sheet を識別 + 表示するための単一 state。
    /// id は presentation 単位で発行する (Session 自身を Identifiable にすると
    /// SwiftData @Model の MainActor 隔離と SendableMetatype 要件が衝突する)。
    struct EditorPresentation: Identifiable {
        let id = UUID()
        let mode: Mode

        enum Mode {
            case add(initialDate: Date)
            case edit(Session)
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("History")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editor = EditorPresentation(mode: .add(initialDate: .now))
                        } label: {
                            Label("Add session", systemImage: "plus")
                        }
                    }
                }
        }
        .sheet(item: $editor) { presentation in
            switch presentation.mode {
            case .add(let date):
                SessionEditorView(mode: .add(initialDate: date))
            case .edit(let session):
                SessionEditorView(mode: .edit(session))
            }
        }
        .confirmationDialog(
            "Delete session?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { session in
            Button("Delete", role: .destructive) { delete(session) }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if sessions.isEmpty {
            ContentUnavailableView(
                "No sessions yet",
                systemImage: "list.bullet",
                description: Text("Start a session from the Timer tab to begin tracking.")
            )
        } else {
            List {
                ForEach(SessionGrouping.byDay(sessions), id: \.date) { group in
                    Section(header: Text(dayHeader(group.date))) {
                        ForEach(group.sessions, id: \.id) { session in
                            SessionRow(session: session)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editor = EditorPresentation(mode: .edit(session))
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        pendingDelete = session
                                        showingDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return String(localized: "Today") }
        if cal.isDateInYesterday(date) { return String(localized: "Yesterday") }
        return Self.dayFormatter.string(from: date)
    }

    private func delete(_ session: Session) {
        modelContext.delete(session)
        try? modelContext.save()
        pendingDelete = nil
    }
}
