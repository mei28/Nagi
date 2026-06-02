import Foundation
import SwiftData

/// 作業セッション 1 件を表すモデル。
///
/// `note` フィールドは JSON エクスポート時に `"description"` キーへマッピングする
/// (Fathom 互換)。Swift 側では `description` が `CustomStringConvertible` と衝突するため
/// `note` 命名にしている。詳細は `docs/OPEN_QUESTIONS.md` Q6 を参照。
@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        note: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 進行中のセッション(終了時刻が未設定)。
    var isActive: Bool { endTime == nil }

    /// 作業時間(秒)。進行中は `nil`。
    var duration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

