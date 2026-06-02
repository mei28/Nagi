import Testing
import Foundation
@testable import Nagi

struct PreferencesTests {

    @Test
    func default_preferences_are_valid() {
        let prefs = Preferences.default
        #expect(prefs.isValid)
        #expect(prefs.breakRatio == 0.20)
        #expect(prefs.rotationMinutes == 30)
        #expect(prefs.notificationEnabled == true)
        #expect(prefs.soundEnabled == true)
        #expect(prefs.language == "system")
    }

    @Test
    func breakRatio_must_be_in_one_to_hundred_percent() {
        var prefs = Preferences.default

        prefs.breakRatio = 0.01
        #expect(prefs.isValid)
        prefs.breakRatio = 1.00
        #expect(prefs.isValid)

        prefs.breakRatio = 0.0
        #expect(!prefs.isValid)
        prefs.breakRatio = 1.01
        #expect(!prefs.isValid)
    }

    @Test
    func rotationMinutes_must_be_in_allowed_set() {
        var prefs = Preferences.default
        for value in [1, 15, 30, 60] {
            prefs.rotationMinutes = value
            #expect(prefs.isValid, "rotationMinutes=\(value) should be valid")
        }
        prefs.rotationMinutes = 45
        #expect(!prefs.isValid)
    }

    @Test
    func language_must_be_in_allowed_set() {
        var prefs = Preferences.default
        for value in ["ja", "en", "system"] {
            prefs.language = value
            #expect(prefs.isValid, "language=\(value) should be valid")
        }
        prefs.language = "fr"
        #expect(!prefs.isValid)
    }

    @Test
    func codable_roundtrip_preserves_values() throws {
        let original = Preferences(
            breakRatio: 0.33,
            rotationMinutes: 15,
            notificationEnabled: false,
            soundEnabled: true,
            language: "ja"
        )
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Preferences.self, from: encoded)
        #expect(decoded == original)
    }
}
