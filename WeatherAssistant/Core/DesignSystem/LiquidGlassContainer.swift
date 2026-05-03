import SwiftUI

struct LiquidGlassContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .background(AppTheme.surface.opacity(0.70), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .stroke(.white.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: AppTheme.accent.opacity(0.10), radius: 22, y: 12)
            .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
    }
}
