import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
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
                    .opacity(reduceMotion ? 0 : 1)
                }
            }
            .mask(content)
            .onAppear {
                guard reduceMotion == false else {
                    phase = 0
                    return
                }

                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .onChange(of: reduceMotion) { _, newValue in
                if newValue {
                    phase = 0
                } else {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
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
    var height: CGFloat = 120
    var cornerRadius: CGFloat = AppTheme.compactRadius

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.elevatedSurface)
            .frame(height: height)
            .modifier(ShimmerModifier())
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
