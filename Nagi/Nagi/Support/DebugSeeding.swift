#if DEBUG
import Foundation
import SwiftData

/// Debug ビルド専用のデータ投入ヘルパ。
///
/// カレンダー/履歴のヒートマップや日付グループを目視確認したいときに、
/// 過去 N 日分のランダムなセッションを一括投入する。Release ビルドからは
/// `#if DEBUG` で除外されるので心配ない。
@MainActor
enum DebugSeeding {

    /// 過去 `days` 日ぶんのランダムなセッションを挿入する。
    /// 1 日 0..4 件、各セッション 15..120 分、note は半数くらい付ける。
    static func seed(into context: ModelContext, days: Int = 60) {
        let now = Date()
        let calendar = Calendar.current
        let noteSamples: [String?] = [
            nil, nil, nil,
            "draft spec", "review PRs", "deep work",
            "writing", "code reading", "meeting"
        ]

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let sessionCount = Int.random(in: 0...4)
            for _ in 0..<sessionCount {
                let startHour = Int.random(in: 8...20)
                let startMinute = Int.random(in: 0..<60)
                let durationMinutes = Int.random(in: 15...120)

                var comps = calendar.dateComponents([.year, .month, .day], from: day)
                comps.hour = startHour
                comps.minute = startMinute
                guard let startTime = calendar.date(from: comps) else { continue }
                let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
                let note = noteSamples.randomElement() ?? nil

                let session = Session(
                    startTime: startTime,
                    endTime: endTime,
                    note: note,
                    createdAt: startTime,
                    updatedAt: endTime
                )
                context.insert(session)
            }
        }
        try? context.save()
    }

    /// 全セッションを削除する。
    static func clearAll(from context: ModelContext) {
        let descriptor = FetchDescriptor<Session>()
        guard let all = try? context.fetch(descriptor) else { return }
        for session in all {
            context.delete(session)
        }
        try? context.save()
    }
}
#endif
