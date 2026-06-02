import Testing
import Foundation
@testable import Nagi

struct CircularTimerGeometryTests {

    // MARK: - currentRotation

    @Test
    func currentRotation_starts_at_one_when_no_elapsed() {
        let n = CircularTimerGeometry.currentRotation(elapsed: 0, rotationSeconds: 1_800)
        #expect(n == 1)
    }

    @Test
    func currentRotation_advances_when_one_full_rotation_passes() {
        let n = CircularTimerGeometry.currentRotation(elapsed: 1_800, rotationSeconds: 1_800)
        #expect(n == 2)
    }

    @Test
    func currentRotation_handles_third_rotation_mid_way() {
        let elapsed: TimeInterval = 1_800 * 2 + 600
        let n = CircularTimerGeometry.currentRotation(elapsed: elapsed, rotationSeconds: 1_800)
        #expect(n == 3)
    }

    @Test
    func currentRotation_returns_one_on_invalid_rotation() {
        let n = CircularTimerGeometry.currentRotation(elapsed: 600, rotationSeconds: 0)
        #expect(n == 1)
    }

    // MARK: - progressInCurrentRotation

    @Test
    func progress_is_zero_at_start() {
        let p = CircularTimerGeometry.progressInCurrentRotation(elapsed: 0, rotationSeconds: 1_800)
        #expect(p == 0)
    }

    @Test
    func progress_is_half_at_midpoint() {
        let p = CircularTimerGeometry.progressInCurrentRotation(elapsed: 900, rotationSeconds: 1_800)
        #expect(p == 0.5)
    }

    @Test
    func progress_wraps_back_to_zero_at_rotation_boundary() {
        let p = CircularTimerGeometry.progressInCurrentRotation(elapsed: 1_800, rotationSeconds: 1_800)
        #expect(p == 0)
    }

    @Test
    func progress_during_second_rotation() {
        let elapsed: TimeInterval = 1_800 + 450  // 2 周目 25%
        let p = CircularTimerGeometry.progressInCurrentRotation(elapsed: elapsed, rotationSeconds: 1_800)
        #expect(p == 0.25)
    }

    @Test
    func progress_returns_zero_on_invalid_rotation() {
        let p = CircularTimerGeometry.progressInCurrentRotation(elapsed: 600, rotationSeconds: 0)
        #expect(p == 0)
    }

    // MARK: - completedRotations

    @Test
    func completedRotations_is_zero_before_first_full() {
        let c = CircularTimerGeometry.completedRotations(elapsed: 1_799, rotationSeconds: 1_800)
        #expect(c == 0)
    }

    @Test
    func completedRotations_increments_at_boundary() {
        let c = CircularTimerGeometry.completedRotations(elapsed: 1_800, rotationSeconds: 1_800)
        #expect(c == 1)
    }

    @Test
    func completedRotations_after_two_and_half() {
        let elapsed: TimeInterval = 1_800 * 2 + 600
        let c = CircularTimerGeometry.completedRotations(elapsed: elapsed, rotationSeconds: 1_800)
        #expect(c == 2)
    }
}
