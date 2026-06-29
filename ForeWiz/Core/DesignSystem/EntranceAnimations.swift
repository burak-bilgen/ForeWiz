import SwiftUI

struct CardEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool
    var baseDelay: Double = 0.06
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(appeared ? 1 : 0)
        } else {
            content
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.95)
                .offset(y: appeared ? 0 : 16)
                .animation(
                    AppTheme.cardSpring
                        .delay(baseDelay + Double(index) * AppTheme.staggerDelay),
                    value: appeared
                )
        }
    }
}

extension View {
    func cardEntrance(index: Int = 0, appeared: Bool, baseDelay: Double = 0.06) -> some View {
        modifier(CardEntranceModifier(index: index, appeared: appeared, baseDelay: baseDelay))
    }
}

struct StaggerEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool
    var baseDelay: Double = 0.06

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                AppTheme.cardSpring
                    .delay(Double(index) * baseDelay),
                value: appeared
            )
    }
}

extension View {
    func staggerEntrance(index: Int, appeared: Bool, baseDelay: Double = 0.06) -> some View {
        modifier(StaggerEntranceModifier(index: index, appeared: appeared, baseDelay: baseDelay))
    }
}

struct FloatModifier: ViewModifier {
    var amplitude: CGFloat = 8
    var duration: Double = 3.0
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    offset = amplitude
                }
            }
    }
}

extension View {
    func floating(amplitude: CGFloat = 8, duration: Double = 3.0) -> some View {
        modifier(FloatModifier(amplitude: amplitude, duration: duration))
    }
}
