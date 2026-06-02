import AppKit
import SwiftUI

/// メニューバー常駐アプリの `NSApplicationDelegate`。
///
/// 振る舞い:
/// - Dock アイコンを出さない (`.accessory`)。`NagiApp.init()` で設定済みだが、
///   起動完了時にも念のため固定する。
/// - 起動時に SwiftUI が自動で開くウィンドウを閉じ、メニューバーのみ常駐させる。
/// - フルウィンドウ表示中だけ `.regular` に切り替え、標準メニューバー
///   (Edit メニューのコピー/ペースト等) とフォーカスを得る。ウィンドウを
///   すべて閉じたら `.accessory` に戻す。
///
/// Rust でいうと「ウィンドウの有無に応じてアプリの“見え方モード”を
/// 切り替える状態管理」を AppKit のライフサイクルにフックしている。
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // SwiftUI の Window シーンは起動時に 1 枚開くため、ここで閉じる。
        // 描画タイミングの都合で次のランループに回す。
        DispatchQueue.main.async {
            self.closeMainWindows()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )

        Task { @MainActor in
            await NotificationService.shared.requestAuthorization()
        }
    }

    /// タイトルバー付きウィンドウ (= フルウィンドウ) をすべて閉じる。
    /// MenuBarExtra のポップアップは borderless なので対象外。
    private func closeMainWindows() {
        for window in NSApp.windows where window.isMainWindowCandidate {
            window.close()
        }
    }

    /// フルウィンドウが閉じられたら、残りにフルウィンドウが無ければ
    /// アクセサリ (Dock 非表示) に戻す。
    ///
    /// ポップアップ (borderless) の close では発火させない。これをしないと
    /// 「Open Nagi…」でポップアップが閉じた瞬間に `.accessory` へ戻ってしまい、
    /// せっかく出した標準メニューバー (コピー/ペースト) が消える。
    @objc private func windowWillClose(_ notification: Notification) {
        guard let closing = notification.object as? NSWindow,
              closing.isMainWindowCandidate else { return }

        // willClose の時点では当該ウィンドウはまだ可視扱いなので、
        // クローズ完了後 (次のランループ) に残りを判定する。
        DispatchQueue.main.async {
            let stillHasMainWindow = NSApp.windows.contains {
                $0.isVisible && $0.isMainWindowCandidate
            }
            if !stillHasMainWindow {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
