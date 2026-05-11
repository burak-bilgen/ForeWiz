import SwiftUI

struct GlassCard<Content: View>: View {
    var accentColor: Color? = nil
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        accentColor != nil
                            ? accentColor!.opacity(0.15)
                            : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
    }
}
