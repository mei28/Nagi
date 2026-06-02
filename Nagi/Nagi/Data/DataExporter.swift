import Foundation

/// Fathom 互換のエクスポート/インポート用 JSON 構造。
///
/// JSON 側の `"description"` キーは Swift の `note` フィールドに `CodingKey` で
/// マッピングする (docs/OPEN_QUESTIONS.md Q6 / docs/MIGRATION_FROM_FATHOM.md 参照)。
struct ExportData: Codable, Equatable {
    var version: String
    var exportedAt: Date
    var sessions: [SessionDTO]
    var settings: Preferences

    static let currentVersion = "1.0"
}

struct SessionDTO: Codable, Equatable {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime
        case note = "description"
        case createdAt, updatedAt
    }
}

extension SessionDTO {
    init(from session: Session) {
        self.init(
            id: session.id,
            startTime: session.startTime,
            endTime: session.endTime,
            note: session.note,
            createdAt: session.createdAt,
            updatedAt: session.updatedAt
        )
    }

    func toSession() -> Session {
        Session(
            id: id,
            startTime: startTime,
            endTime: endTime,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// JSON のエクスポート/インポートを担うエントリポイント。
///
/// 日付はミリ秒つき ISO 8601 で書き出し、読み込みはミリ秒あり/なし両対応する
/// (Fathom 実装が `"2026-01-29T08:00:00.000Z"` 形式を出力するため)。
enum DataExporter {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: str) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO 8601 date: \(str)"
            )
        }
        return decoder
    }

    @MainActor
    static func encode(
        sessions: [Session],
        preferences: Preferences,
        at exportedAt: Date
    ) throws -> Data {
        let payload = ExportData(
            version: ExportData.currentVersion,
            exportedAt: exportedAt,
            sessions: sessions.map(SessionDTO.init(from:)),
            settings: preferences
        )
        return try makeEncoder().encode(payload)
    }

    static func decode(_ data: Data) throws -> ExportData {
        try makeDecoder().decode(ExportData.self, from: data)
    }
}
