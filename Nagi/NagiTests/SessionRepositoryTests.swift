import Testing
import Foundation
import SwiftData
@testable import Nagi

@MainActor
struct SessionRepositoryTests {

    private func makeRepo() throws -> SwiftDataSessionRepository {
        let schema = Schema([Session.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return SwiftDataSessionRepository(context: ModelContext(container))
    }

    @Test
    func create_and_list_returns_inserted_session() async throws {
        let repo = try makeRepo()
        let now = Date(timeIntervalSince1970: 1_000)
        let session = Session(startTime: now, createdAt: now, updatedAt: now)

        try await repo.create(session)
        let all = try await repo.list(limit: nil, offset: nil)

        #expect(all.count == 1)
        #expect(all.first?.id == session.id)
    }

    @Test
    func list_is_sorted_by_startTime_descending() async throws {
        let repo = try makeRepo()
        let base = Date(timeIntervalSince1970: 0)
        let older = Session(startTime: base, createdAt: base, updatedAt: base)
        let newer = Session(startTime: base.addingTimeInterval(3_600),
                            createdAt: base, updatedAt: base)

        try await repo.create(older)
        try await repo.create(newer)
        let all = try await repo.list(limit: nil, offset: nil)

        #expect(all.map(\.id) == [newer.id, older.id])
    }

    @Test
    func stop_sets_endTime_and_updates_updatedAt() async throws {
        let repo = try makeRepo()
        let start = Date(timeIntervalSince1970: 1_000)
        let session = Session(startTime: start, createdAt: start, updatedAt: start)
        try await repo.create(session)

        let end = Date(timeIntervalSince1970: 4_000)
        let stopped = try await repo.stop(id: session.id, at: end)

        #expect(stopped.endTime == end)
        #expect(stopped.updatedAt == end)
        #expect(stopped.duration == 3_000)
    }

    @Test
    func stop_throws_notFound_for_unknown_id() async throws {
        let repo = try makeRepo()
        let unknown = UUID()

        await #expect(throws: RepositoryError.notFound(id: unknown)) {
            _ = try await repo.stop(id: unknown, at: Date())
        }
    }

    @Test
    func activeSession_returns_only_session_without_endTime() async throws {
        let repo = try makeRepo()
        let base = Date(timeIntervalSince1970: 0)
        let finished = Session(
            startTime: base, endTime: base.addingTimeInterval(60),
            createdAt: base, updatedAt: base
        )
        let active = Session(
            startTime: base.addingTimeInterval(120),
            createdAt: base, updatedAt: base
        )

        try await repo.create(finished)
        try await repo.create(active)
        let result = try await repo.activeSession()

        #expect(result?.id == active.id)
    }

    @Test
    func activeSession_returns_nil_when_all_finished() async throws {
        let repo = try makeRepo()
        let now = Date()
        let s = Session(startTime: now, endTime: now.addingTimeInterval(60),
                        createdAt: now, updatedAt: now)
        try await repo.create(s)

        #expect(try await repo.activeSession() == nil)
    }

    @Test
    func update_bumps_updatedAt() async throws {
        let repo = try makeRepo()
        let start = Date(timeIntervalSince1970: 1_000)
        let session = Session(startTime: start, createdAt: start, updatedAt: start)
        try await repo.create(session)
        let before = session.updatedAt

        session.note = "edited"
        try await repo.update(session)

        #expect(session.updatedAt > before)
        #expect(session.note == "edited")
    }

    @Test
    func delete_removes_session() async throws {
        let repo = try makeRepo()
        let now = Date()
        let session = Session(startTime: now, createdAt: now, updatedAt: now)
        try await repo.create(session)

        try await repo.delete(id: session.id)
        let all = try await repo.list(limit: nil, offset: nil)
        #expect(all.isEmpty)
    }

    @Test
    func delete_throws_notFound_for_unknown_id() async throws {
        let repo = try makeRepo()
        let unknown = UUID()
        await #expect(throws: RepositoryError.notFound(id: unknown)) {
            try await repo.delete(id: unknown)
        }
    }

    @Test
    func list_respects_limit_and_offset() async throws {
        let repo = try makeRepo()
        let base = Date(timeIntervalSince1970: 0)
        for i in 0..<5 {
            let s = Session(
                startTime: base.addingTimeInterval(TimeInterval(i) * 60),
                createdAt: base, updatedAt: base
            )
            try await repo.create(s)
        }

        let page = try await repo.list(limit: 2, offset: 1)
        #expect(page.count == 2)
    }
}
