import Testing
import Foundation
@testable import Nagi

struct SessionTests {

    @Test
    func active_session_has_no_endTime() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let session = Session(startTime: now, createdAt: now, updatedAt: now)

        #expect(session.endTime == nil)
        #expect(session.isActive == true)
        #expect(session.duration == nil)
    }

    @Test
    func completed_session_duration_is_interval_in_seconds() {
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_500)
        let session = Session(
            startTime: start,
            endTime: end,
            createdAt: start,
            updatedAt: end
        )

        #expect(session.isActive == false)
        #expect(session.duration == 1_500)
    }

    @Test
    func id_is_unique_per_instance_by_default() {
        let now = Date()
        let a = Session(startTime: now, createdAt: now, updatedAt: now)
        let b = Session(startTime: now, createdAt: now, updatedAt: now)
        #expect(a.id != b.id)
    }

    @Test
    func note_is_optional_and_defaults_to_nil() {
        let now = Date()
        let session = Session(startTime: now, createdAt: now, updatedAt: now)
        #expect(session.note == nil)
    }
}
