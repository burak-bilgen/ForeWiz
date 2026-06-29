import SwiftUI

struct LiquidOrbBackground: View {
    var palette: OrbPalette = .default
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

        var animationSpeed: Double {
            switch self {
            case .stormy:        return 1.8
            case .default:       return 1.2
            case .clearSky:      return 0.7
            case .sunset:        return 0.65
            case .snowy:         return 0.55
            case .night:         return 0.45
            }
        }
    }

    var body: some View {
        if reduceMotion {
            staticContent
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                animatedContent(time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private var staticContent: some View {
        GeometryReader { geometry in
            let w = max(geometry.size.width, 1)
            let h = max(geometry.size.height, 1)
            let base = min(w, h)

            ZStack {
                LinearGradient(
                    colors: [palette.colors.base1, palette.colors.base2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: w, height: h)
                .clipped()

                DriftingOrb(
                    color: palette.colors.primary,
                    opacity: 0.18,
                    size: base * 0.95,
                    blur: base * 0.16,
                    xOffset: 0.20,
                    yOffset: 0.05
                )

                DriftingOrb(
                    color: palette.colors.secondary,
                    opacity: 0.12,
                    size: base * 0.62,
                    blur: base * 0.14,
                    xOffset: 0.85,
                    yOffset: 0.82
                )

                DriftingOrb(
                    color: palette.colors.tertiary,
                    opacity: 0.10,
                    size: base * 0.44,
                    blur: base * 0.10,
                    xOffset: 0.58,
                    yOffset: 0.34
                )
            }
        }
    }

    private func animatedContent(time: TimeInterval) -> some View {
        let speed = palette.animationSpeed
        let t = time * speed

        let phase1 = t * 0.12
        let phase2 = t * 0.09 + 1.7
        let phase3 = t * 0.07 + 3.1

        return GeometryReader { geometry in
            let w = max(geometry.size.width, 1)
            let h = max(geometry.size.height, 1)
            let base = min(w, h)

            ZStack {

                LinearGradient(
                    colors: [palette.colors.base1, palette.colors.base2],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                DriftingOrb(
                    color: palette.colors.primary,
                    opacity: 0.18 + sin(phase1 * 1.8) * 0.035,
                    size: base * (0.95 + sin(phase1 * 0.8) * 0.06),
                    blur: base * 0.16,
                    xOffset: 0.20 + sin(phase1) * 0.10,
                    yOffset: 0.05 + cos(phase1 * 0.7) * 0.08
                )

                DriftingOrb(
                    color: palette.colors.secondary,
                    opacity: 0.12 + sin(phase2 * 1.5) * 0.03,
                    size: base * (0.62 + sin(phase2 * 1.1) * 0.05),
                    blur: base * 0.14,
                    xOffset: 0.85 + sin(phase2 * 0.75) * 0.08,
                    yOffset: 0.82 + cos(phase2 * 1.2) * 0.06
                )

                DriftingOrb(
                    color: palette.colors.tertiary,
                    opacity: 0.10 + sin(phase3 * 2.0) * 0.025,
                    size: base * (0.44 + sin(phase3 * 0.9) * 0.04),
                    blur: base * 0.10,
                    xOffset: 0.58 + sin(phase3 * 0.6) * 0.12,
                    yOffset: 0.34 + cos(phase3 * 0.8) * 0.10
                )
            }
            .frame(width: w, height: h)
            .clipped()

            .drawingGroup()
        }
    }
}

private struct DriftingOrb: View {
    let color: Color
    let opacity: Double
    let size: CGFloat
    let blur: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Ellipse()
                .fill(color)
                .opacity(opacity)
                .frame(width: size, height: size * 0.82)
                .blur(radius: blur)
                .position(
                    x: geometry.size.width * xOffset,
                    y: geometry.size.height * yOffset
                )
        }
    }
}

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

    }
}
