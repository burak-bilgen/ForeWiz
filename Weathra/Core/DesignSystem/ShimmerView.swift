import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct ShimmerView: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.elevatedSurface)
            .modifier(ShimmerModifier())
    }
}

struct LoadingCardPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
            .fill(AppTheme.elevatedSurface)
            .frame(height: 120)
            .modifier(ShimmerModifier())
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}