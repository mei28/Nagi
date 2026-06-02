import Foundation
import SwiftData

/// セッションの永続化を抽象化するインターフェイス。
///
/// SwiftData 実装の他に、将来 GRDB 等で差し替えられるようにするためのプロトコル。
@MainActor
protocol SessionRepository {
    func create(_ session: Session) async throws
    func stop(id: UUID, at endTime: Date) async throws -> Session
    func list(limit: Int?, offset: Int?) async throws -> [Session]
    func activeSession() async throws -> Session?
    func update(_ session: Session) async throws
    func delete(id: UUID) async throws
}

enum RepositoryError: Error, Equatable {
    case notFound(id: UUID)
}

/// SwiftData 実装。`ModelContext` を `@MainActor` で扱う前提。
@MainActor
final class SwiftDataSessionRepository: SessionRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func create(_ session: Session) async throws {
        context.insert(session)
        try context.save()
    }

    func stop(id: UUID, at endTime: Date) async throws -> Session {
        guard let session = try fetchOne(id: id) else {
            throw RepositoryError.notFound(id: id)
        }
        session.endTime = endTime
        session.updatedAt = endTime
        try context.save()
        return session
    }

    func list(limit: Int? = nil, offset: Int? = nil) async throws -> [Session] {
        var descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try context.fetch(descriptor)
    }

    func activeSession() async throws -> Session? {
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func update(_ session: Session) async throws {
        session.updatedAt = .now
        try context.save()
    }

    func delete(id: UUID) async throws {
        guard let session = try fetchOne(id: id) else {
            throw RepositoryError.notFound(id: id)
        }
        context.delete(session)
        try context.save()
    }

    private func fetchOne(id: UUID) throws -> Session? {
        var descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
