import SwiftUI

struct LiquidSheenModifier: ViewModifier {
    let accentColor: Color
    let isActive: Bool
    @State private var phase: CGFloat = -0.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0),
                                accentColor.opacity(0.10),
                                .white.opacity(0.05),
                                accentColor.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 1.5)
                        .offset(x: phase * geo.size.width * 1.5)
                        .blendMode(.plusLighter)
                    }
                        .clipped()
                )
                .onAppear {
                    withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false).delay(0.5)) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func liquidSheen(accent: Color = AppTheme.liquidAccent, isActive: Bool = true) -> some View {
        modifier(LiquidSheenModifier(accentColor: accent, isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0
    var isActive: Bool = true

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .white.opacity(0),
                                .white.opacity(0.15),
                                .white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.55)
                        .offset(x: phase * (geo.size.width + geo.size.width * 0.55))
                        .blendMode(.plusLighter)
                    }
                        .clipped()
                )
                .onAppear {
                    withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false).delay(0.4)) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}
