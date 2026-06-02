import Foundation

/// アプリ設定 (永続化は UserDefaults / @AppStorage、エクスポート時にも DTO 兼用)。
///
/// - `breakRatio`: 1〜100%。既定 0.20 (= 20%)
/// - `rotationMinutes`: 円形タイマー 1 周の長さ。{1, 15, 30, 60}。既定 30
/// - `language`: "ja" / "en" / "system"。既定 "system" (起動時に Locale から解決)
struct Preferences: Codable, Equatable {
    var breakRatio: Double
    var rotationMinutes: Int
    var notificationEnabled: Bool
    var soundEnabled: Bool
    var language: String

    static let `default` = Preferences(
        breakRatio: 0.20,
        rotationMinutes: 30,
        notificationEnabled: true,
        soundEnabled: true,
        language: "system"
    )

    static let allowedRotationMinutes: Set<Int> = [1, 15, 30, 60]
    static let allowedLanguages: Set<String> = ["ja", "en", "system"]
    static let breakRatioRange: ClosedRange<Double> = 0.01...1.00

    var isValid: Bool {
        Self.breakRatioRange.contains(breakRatio)
            && Self.allowedRotationMinutes.contains(rotationMinutes)
            && Self.allowedLanguages.contains(language)
    }
}
