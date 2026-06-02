import Foundation

/// 履歴画面で 1 日分の Session 群をまとめる箱。
struct SessionDayGroup {
    let date: Date      // 日付の開始時刻 (calendar.startOfDay)
    let sessions: [Session]
}

/// セッション配列を日付セクションに分けるための pure ヘルパ。
///
/// View 層から切り出してテスタブルにしてあるが、Session が `@MainActor` 隔離なので
/// このユーティリティ自体も `@MainActor` で動かす。
@MainActor
enum SessionGrouping {
    /// `startTime` を `calendar.startOfDay` で丸めた日付をキーにグループ化する。
    /// 日付は降順 (新しい日から)、各日内のセッションも `startTime` 降順で並べる。
    static func byDay(_ sessions: [Session], calendar: Calendar = .current) -> [SessionDayGroup] {
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped
            .map { (date, items) in
                SessionDayGroup(
                    date: date,
                    sessions: items.sorted { $0.startTime > $1.startTime }
                )
            }
            .sorted { $0.date > $1.date }
    }
}
