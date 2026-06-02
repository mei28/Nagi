import SwiftUI

/// 履歴リストの 1 行。時刻範囲 / 作業時間 / メモ抜粋を 2 段で表示する。
struct SessionRow: View {
    let session: Session

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(timeRange)
                    .font(.callout)
                    .monospacedDigit()
                Spacer()
                Text(durationText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if let note = session.note, !note.isEmpty {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        let start = Self.timeFormatter.string(from: session.startTime)
        if let end = session.endTime {
            return "\(start) – \(Self.timeFormatter.string(from: end))"
        }
        return "\(start) – …"
    }

    private var durationText: String {
        guard let duration = session.duration else { return String(localized: "in progress") }
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
