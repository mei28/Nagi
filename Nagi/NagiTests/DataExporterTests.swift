import Testing
import Foundation
@testable import Nagi

@MainActor
struct DataExporterTests {

    @Test
    func sessionDTO_writes_description_key_not_note() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let dto = SessionDTO(
            id: UUID(),
            startTime: now,
            endTime: nil,
            note: "drafting",
            createdAt: now,
            updatedAt: now
        )

        let data = try DataExporter.makeEncoder().encode(dto)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains("\"description\""))
        #expect(!json.contains("\"note\""))
    }

    @Test
    func encode_decode_roundtrip_preserves_data() throws {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let sessions = [
            Session(startTime: base, endTime: base.addingTimeInterval(600),
                    note: "first", createdAt: base, updatedAt: base),
            Session(startTime: base.addingTimeInterval(1_000),
                    note: nil, createdAt: base, updatedAt: base)
        ]
        let prefs = Preferences(
            breakRatio: 0.25,
            rotationMinutes: 15,
            notificationEnabled: false,
            soundEnabled: true,
            language: "ja"
        )
        let exportedAt = base.addingTimeInterval(7_200)

        let data = try DataExporter.encode(
            sessions: sessions, preferences: prefs, at: exportedAt
        )
        let decoded = try DataExporter.decode(data)

        #expect(decoded.version == "1.0")
        #expect(decoded.exportedAt == exportedAt)
        #expect(decoded.sessions.count == 2)
        #expect(decoded.sessions[0].note == "first")
        #expect(decoded.sessions[1].note == nil)
        #expect(decoded.settings == prefs)
    }

    @Test
    func decode_accepts_fathom_sample_with_fractional_seconds() throws {
        let json = """
        {
          "version": "1.0",
          "exportedAt": "2026-01-29T08:00:00.000Z",
          "sessions": [
            {
              "id": "550E8400-E29B-41D4-A716-446655440000",
              "startTime": "2026-01-29T07:00:00.000Z",
              "endTime":   "2026-01-29T07:50:00.000Z",
              "description": "spec drafting",
              "createdAt": "2026-01-29T07:00:00.000Z",
              "updatedAt": "2026-01-29T07:50:00.000Z"
            }
          ],
          "settings": {
            "breakRatio": 0.20,
            "rotationMinutes": 30,
            "notificationEnabled": true,
            "soundEnabled": true,
            "language": "ja"
          }
        }
        """.data(using: .utf8)!

        let export = try DataExporter.decode(json)

        #expect(export.version == "1.0")
        #expect(export.sessions.count == 1)
        let s = try #require(export.sessions.first)
        #expect(s.note == "spec drafting")
        #expect(s.id == UUID(uuidString: "550E8400-E29B-41D4-A716-446655440000"))
        #expect(s.endTime?.timeIntervalSince(s.startTime) == 3_000)
        #expect(export.settings.breakRatio == 0.20)
        #expect(export.settings.language == "ja")
    }

    @Test
    func decode_accepts_dates_without_fractional_seconds() throws {
        let json = """
        {
          "version": "1.0",
          "exportedAt": "2026-01-29T08:00:00Z",
          "sessions": [],
          "settings": {
            "breakRatio": 0.20,
            "rotationMinutes": 30,
            "notificationEnabled": true,
            "soundEnabled": true,
            "language": "en"
          }
        }
        """.data(using: .utf8)!

        let export = try DataExporter.decode(json)
        #expect(export.sessions.isEmpty)
        #expect(export.settings.language == "en")
    }

    @Test
    func decode_throws_on_invalid_date_string() throws {
        let json = """
        {
          "version": "1.0",
          "exportedAt": "not-a-date",
          "sessions": [],
          "settings": {
            "breakRatio": 0.20,
            "rotationMinutes": 30,
            "notificationEnabled": true,
            "soundEnabled": true,
            "language": "ja"
          }
        }
        """.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            _ = try DataExporter.decode(json)
        }
    }

    @Test
    func session_to_dto_and_back_preserves_all_fields() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let original = Session(
            startTime: now,
            endTime: now.addingTimeInterval(900),
            note: "hi",
            createdAt: now,
            updatedAt: now.addingTimeInterval(900)
        )
        let dto = SessionDTO(from: original)
        let restored = dto.toSession()

        #expect(restored.id == original.id)
        #expect(restored.startTime == original.startTime)
        #expect(restored.endTime == original.endTime)
        #expect(restored.note == original.note)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }
}
