import Combine
import SwiftUI

// MARK: - Animated floating orb background

struct AnimatedOrbBackground: View {
    var primary: Color = Color(red: 0.3, green: 0.5, blue: 1.0)
    var secondary: Color = Color(red: 0.5, green: 0.3, blue: 1.0)
    var tertiary: Color = Color(red: 0.2, green: 0.7, blue: 0.9)
    var baseColor1: Color = Color(red: 0.04, green: 0.06, blue: 0.14)
    var baseColor2: Color = Color(red: 0.05, green: 0.09, blue: 0.20)

    @State private var phase: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let base = min(width, height)

            ZStack {
                LinearGradient(
                    colors: [baseColor1, baseColor2],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                Ellipse()
                    .fill(primary.opacity(0.20))
                    .frame(width: base * 0.95, height: base * 0.78)
                    .blur(radius: base * 0.16)
                    .position(
                        x: width * 0.20 + CGFloat(sin(phase * 0.7)) * 18,
                        y: height * 0.05 + CGFloat(cos(phase * 0.5)) * 14
                    )

                Circle()
                    .fill(secondary.opacity(0.12))
                    .frame(width: base * 0.62, height: base * 0.62)
                    .blur(radius: base * 0.13)
                    .position(
                        x: width * 0.85 + CGFloat(cos(phase * 0.9)) * 20,
                        y: height * 0.82 + CGFloat(sin(phase * 0.6)) * 16
                    )

                Circle()
                    .fill(tertiary.opacity(0.10))
                    .frame(width: base * 0.44, height: base * 0.44)
                    .blur(radius: base * 0.10)
                    .position(
                        x: width * 0.58 + CGFloat(sin(phase * 1.2)) * 24,
                        y: height * 0.34 + CGFloat(cos(phase * 0.8)) * 20
                    )
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Shimmer modifier

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
                                Color.white.opacity(0),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0)
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

// MARK: - Press scale button style

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressScaleButtonStyle(scale: scale))
    }
}

// MARK: - Stagger entrance modifier

struct StaggerEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool
    var baseDelay: Double = 0.06

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82)
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

// MARK: - Pulse glow modifier

struct PulseGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 14
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulse ? 0.55 : 0.2), radius: pulse ? radius : radius * 0.5, x: 0, y: 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

extension View {
    func pulseGlow(color: Color, radius: CGFloat = 14) -> some View {
        modifier(PulseGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Pulsing dots loader

struct PulsingDotsLoader: View {
    var color: Color = .white
    var dotSize: CGFloat = 7
    @State private var phase: Int = 0
    @State private var timer: AnyCancellable?

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 1.0 : 0.28))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.55), value: phase)
            }
        }
        .onAppear {
            timer = Timer.publish(every: 0.35, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    phase = (phase + 1) % 3
                }
        }
        .onDisappear {
            timer?.cancel()
            phase = 0
        }
    }
}

// MARK: - Skeleton shimmer modifier

struct SkeletonModifier: ViewModifier {
    @State private var phase: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(0.09), location: 0.45),
                            .init(color: Color.white.opacity(0.18), location: 0.50),
                            .init(color: Color.white.opacity(0.09), location: 0.55),
                            .init(color: Color.white.opacity(0), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: phase * (geo.size.width * 2))
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }
}

// MARK: - Floating animation modifier

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
