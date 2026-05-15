import Combine
import SwiftUI

// MARK: - Animated Liquid Orb Background
/// Fluid, morphing orb background with liquid glass aesthetic.
struct LiquidOrbBackground: View {
    var palette: OrbPalette = .default
    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum OrbPalette {
        case `default`
        case clearSky
        case stormy
        case night
        case sunset
        case snowy

        var colors: (primary: Color, secondary: Color, tertiary: Color, base1: Color, base2: Color) {
            switch self {
            case .default:
                (Color(red: 0.25, green: 0.50, blue: 1.0),
                 Color(red: 0.50, green: 0.30, blue: 1.0),
                 Color(red: 0.20, green: 0.70, blue: 0.90),
                 Color(red: 0.04, green: 0.06, blue: 0.14),
                 Color(red: 0.05, green: 0.09, blue: 0.20))
            case .clearSky:
                (Color(red: 0.35, green: 0.65, blue: 1.0),
                 Color(red: 0.55, green: 0.75, blue: 1.0),
                 Color(red: 1.0, green: 0.85, blue: 0.45),
                 Color(red: 0.04, green: 0.08, blue: 0.16),
                 Color(red: 0.06, green: 0.12, blue: 0.22))
            case .stormy:
                (Color(red: 0.45, green: 0.25, blue: 0.80),
                 Color(red: 0.25, green: 0.15, blue: 0.60),
                 Color(red: 0.60, green: 0.30, blue: 0.90),
                 Color(red: 0.03, green: 0.03, blue: 0.08),
                 Color(red: 0.06, green: 0.05, blue: 0.12))
            case .night:
                (Color(red: 0.10, green: 0.15, blue: 0.30),
                 Color(red: 0.08, green: 0.12, blue: 0.25),
                 Color(red: 0.15, green: 0.20, blue: 0.35),
                 Color(red: 0.02, green: 0.03, blue: 0.06),
                 Color(red: 0.03, green: 0.05, blue: 0.10))
            case .sunset:
                (Color(red: 1.0, green: 0.45, blue: 0.20),
                 Color(red: 0.95, green: 0.35, blue: 0.55),
                 Color(red: 0.70, green: 0.30, blue: 0.80),
                 Color(red: 0.08, green: 0.04, blue: 0.06),
                 Color(red: 0.12, green: 0.06, blue: 0.10))
            case .snowy:
                (Color(red: 0.55, green: 0.75, blue: 0.95),
                 Color(red: 0.70, green: 0.85, blue: 1.0),
                 Color(red: 0.80, green: 0.90, blue: 1.0),
                 Color(red: 0.06, green: 0.08, blue: 0.12),
                 Color(red: 0.10, green: 0.12, blue: 0.18))
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let w = max(geometry.size.width, 1)
            let h = max(geometry.size.height, 1)
            let base = min(w, h)

            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [palette.colors.base1, palette.colors.base2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Primary orb — large, slow
                LiquidOrb(
                    color: palette.colors.primary,
                    opacity: 0.18,
                    size: base * 0.95,
                    blur: base * 0.16,
                    xOffset: 0.20,
                    yOffset: 0.05,
                    xSpeed: 0.7,
                    ySpeed: 0.5,
                    phase: phase
                )

                // Secondary orb — medium
                LiquidOrb(
                    color: palette.colors.secondary,
                    opacity: 0.12,
                    size: base * 0.62,
                    blur: base * 0.13,
                    xOffset: 0.85,
                    yOffset: 0.82,
                    xSpeed: 0.9,
                    ySpeed: 0.6,
                    phase: phase
                )

                // Tertiary orb — small, fast
                LiquidOrb(
                    color: palette.colors.tertiary,
                    opacity: 0.10,
                    size: base * 0.44,
                    blur: base * 0.10,
                    xOffset: 0.58,
                    yOffset: 0.34,
                    xSpeed: 1.2,
                    ySpeed: 0.8,
                    phase: phase
                )
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Liquid Orb Component

private struct LiquidOrb: View {
    let color: Color
    let opacity: Double
    let size: CGFloat
    let blur: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
    let xSpeed: Double
    let ySpeed: Double
    let phase: Double

    var body: some View {
        GeometryReader { geometry in
            Ellipse()
                .fill(color)
                .opacity(opacity)
                .frame(width: size, height: size * 0.82)
                .blur(radius: blur)
                .position(
                    x: geometry.size.width * xOffset + CGFloat(sin(phase * xSpeed)) * 18,
                    y: geometry.size.height * yOffset + CGFloat(cos(phase * ySpeed)) * 14
                )
        }
    }
}

// MARK: - Legacy AnimatedOrbBackground

struct AnimatedOrbBackground: View {
    var primary: Color = Color(red: 0.3, green: 0.5, blue: 1.0)
    var secondary: Color = Color(red: 0.5, green: 0.3, blue: 1.0)
    var tertiary: Color = Color(red: 0.2, green: 0.7, blue: 0.9)

    var body: some View {
        LiquidOrbBackground(
            palette: .init(
                colors: (primary, secondary, tertiary,
                         Color(red: 0.04, green: 0.06, blue: 0.14),
                         Color(red: 0.05, green: 0.09, blue: 0.20))
            )
        )
    }
}

extension LiquidOrbBackground.OrbPalette {
    init(colors: (primary: Color, secondary: Color, tertiary: Color, base1: Color, base2: Color)) {
        self = .default
        // Dynamic palette creation for legacy support
    }
}

// MARK: - Liquid Sheen Modifier

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

// MARK: - Card Entrance Animation

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
                    .spring(response: 0.5, dampingFraction: 0.82)
                        .delay(baseDelay + Double(index) * 0.06),
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

// MARK: - Shimmer Modifier

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

// MARK: - Button Styles

struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct FullTapAreaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == FullTapAreaButtonStyle {
    static var fullTapArea: FullTapAreaButtonStyle { FullTapAreaButtonStyle() }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.96) -> some View {
        buttonStyle(PressScaleButtonStyle(scale: scale))
    }
}

// MARK: - Pulse Glow Modifier

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

// MARK: - Pulsing Dots Loader

struct PulsingDotsLoader: View {
    var color: Color = .white
    var dotSize: CGFloat = 7
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 1.0 : 0.28))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(phase == i ? 1.4 : 1.0)
            }
        }
        .onReceive(Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - Floating Animation

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

// MARK: - Stagger Entrance (Legacy Support)

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

// MARK: - Preview

#Preview {
    ZStack {
        LiquidOrbBackground(palette: .clearSky)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Liquid Glass Animations")
                .font(.title)
                .foregroundStyle(.white)

            PulsingDotsLoader()
                .floating(amplitude: 6, duration: 3)
        }
    }
}
