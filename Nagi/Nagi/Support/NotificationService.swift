import Foundation
import UserNotifications

/// `UNUserNotificationCenter` の薄いラッパ。
///
/// 休憩終了の予約と取消、認可リクエストだけ提供する。Phase 4 では
/// システム標準のアラート音を使い、カスタム音源は Phase 8 で導入。
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private static let breakEndIdentifier = "com.waddlier.Nagi.breakEnd"

    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// 通知の認可をリクエスト。初回起動時に呼び、却下されてもアプリは動作する。
    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// 休憩終了通知を予約する。
    ///
    /// - Parameters:
    ///   - duration: 通知を出すまでの秒数 (= 休憩予定時間)
    ///   - playSound: サウンドを再生するか (Preferences 連動)
    func scheduleBreakEnd(after duration: TimeInterval, playSound: Bool) async throws {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Break complete")
        content.body = String(localized: "Time to get back to it.")
        content.sound = playSound ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, duration),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.breakEndIdentifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    /// 予約済み休憩終了通知を取り消す (スキップや早期終了時)。
    func cancelBreakEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.breakEndIdentifier])
    }
}
