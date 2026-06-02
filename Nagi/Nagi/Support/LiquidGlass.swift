import SwiftUI

/// Liquid Glass 風の背景を提供するヘルパ。
///
/// macOS 26 (Tahoe) 以降は SwiftUI の `.glassEffect()` を使う。
/// それ以前は `.regularMaterial` + ハイライトグラデで近似する。
extension View {
    /// 全体ポップアップ向けの Glass 背景 (角丸 16)。
    func liquidGlassBackground(cornerRadius: CGFloat = 16) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius))
    }

    /// セクションカード向けの Glass 背景 (角丸 12)。
    func liquidGlassCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius))
    }
}

private struct LiquidGlassBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.background(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content.background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                    }
            }
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        }
    }
}

private struct LiquidGlassCard: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content.background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                    }
            }
        }
    }
}
