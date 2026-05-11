import SwiftUI

struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    var innerPadding: CGFloat = 16
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(innerPadding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white.opacity(0.025))
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        accentColor != nil
                            ? accentColor!.opacity(0.12)
                            : .white.opacity(0.06),
                        lineWidth: 1
                    )
            )
    }
}
