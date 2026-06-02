import AppKit
import Foundation
import UniformTypeIdentifiers

/// JSON のエクスポート/インポート用ファイルピッカ。
///
/// 実際の Codable 処理は `DataExporter` に委譲する。
/// この型は `NSSavePanel` / `NSOpenPanel` の操作と `Data` の読み書きを担当。
@MainActor
enum ExportImportService {

    /// `NSSavePanel` を出して URL を取得し、エクスポートデータを書き込む。
    /// 成功時 `true`、ユーザーキャンセル時 `false`。例外は `NSAlert` で表示。
    @discardableResult
    static func runExport(
        sessions: [Session],
        preferences: Preferences
    ) -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultExportFilename()

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        do {
            let data = try DataExporter.encode(
                sessions: sessions,
                preferences: preferences,
                at: Date()
            )
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            NSAlert(error: error).runModal()
            return false
        }
    }

    /// `NSOpenPanel` を出して URL を取得し、`ExportData` をデコードして返す。
    /// 失敗時は `NSAlert` を出して `nil` を返す。ユーザーキャンセル時も `nil`。
    static func runImport() -> ExportData? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try DataExporter.decode(data)
        } catch {
            NSAlert(error: error).runModal()
            return nil
        }
    }

    private static func defaultExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "nagi-export-\(formatter.string(from: Date())).json"
    }
}
