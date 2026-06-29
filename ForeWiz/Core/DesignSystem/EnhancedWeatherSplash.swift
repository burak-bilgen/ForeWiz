import SwiftUI

struct EnhancedWeatherSplashOverlay: View {
    let kind: EnhancedWeatherSplashKind
    let onDismiss: () -> Void
    var onFadeOut: (() -> Void)?

    @State private var opacity = 0.0
    @State private var iconScale: CGFloat = 0.2
    @State private var iconOpacity: Double = 0.0
    @State private var iconRotation: Double = -30
    @State private var particlesOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var dismissed = false
    @State private var pulseScale: CGFloat = 1.0

    private let totalDuration: Double = 2.8
    private let fadeInDuration: Double = 0.6
    private let fadeOutDuration: Double = 0.9
    private let iconHoldDuration: Double = 1.6

    var body: some View {
        ZStack {
            WeatherSplashGradientBackground(colors: kind.accentColors, opacity: opacity)
            EnhancedWeatherParticles(kind: kind, progress: particlesOpacity)

            RadialGradient(
                colors: [
                    kind.accentColors[0].opacity(glowOpacity * 0.5),
                    kind.accentColors[1].opacity(glowOpacity * 0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            .opacity(glowOpacity)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(kind.accentColors[0].opacity(glowOpacity * 0.6), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)

                    if let secondary = kind.secondaryIcon {
                        Image(systemName: secondary)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(kind.accentColors[2])
                            .opacity(iconOpacity * 0.7)
                            .offset(x: 70, y: 0)
                            .rotationEffect(.degrees(iconRotation * 0.5))
                    }

                    Image(systemName: kind.icon)
                        .font(.system(size: 80, weight: .medium))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(kind.accentColors[0])
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .rotationEffect(.degrees(iconRotation))
                        .shadow(color: kind.accentColors[0].opacity(0.8), radius: 40, x: 0, y: 0)

                    Circle()
                        .fill(kind.accentColors[1].opacity(0.2 * glowOpacity))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                }
                .frame(width: 160, height: 160)

                Text(kind.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .shadow(color: kind.accentColors[0].opacity(0.5), radius: 10)
            }
        }
        .allowsHitTesting(false)
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        Task { @MainActor in
            switch kind.hapticStyle {
            case .light: HapticEngine.shared.light()
            case .medium: HapticEngine.shared.medium()
            case .heavy: HapticEngine.shared.heavy()
            }
        }

        withAnimation(.easeOut(duration: fadeInDuration)) { opacity = 1.0 }
        withAnimation(.easeInOut(duration: 0.4).delay(0.1)) { glowOpacity = 1.0 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
            iconScale = 1.0; iconOpacity = 1.0; iconRotation = 0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.25)) { particlesOpacity = 1.0 }
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) { textOpacity = 1.0 }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.6)) {
            pulseScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + iconHoldDuration) {
            withAnimation(.easeOut(duration: 0.3)) { textOpacity = 0.0 }
            withAnimation(.easeIn(duration: 0.5)) {
                iconScale = 1.5; iconOpacity = 0.0; glowOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - fadeOutDuration) {
            onFadeOut?()
            withAnimation(.easeOut(duration: fadeOutDuration)) {
                opacity = 0.0; particlesOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            dismissed = true
            onDismiss()
        }
    }
}

struct WeatherSplashGradientBackground: View {
    let colors: [Color]
    let opacity: Double

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            LinearGradient(
                colors: animatedColors(for: timeline.date),
                startPoint: UnitPoint(x: 0.5 + sin(timeline.date.timeIntervalSinceReferenceDate * 0.3) * 0.3,
                                      y: 0.0),
                endPoint: UnitPoint(x: 0.5 + cos(timeline.date.timeIntervalSinceReferenceDate * 0.2) * 0.3,
                                    y: 1.0)
            )
            .opacity(opacity * 0.35)
            .ignoresSafeArea()
        }
    }

    private func animatedColors(for date: Date) -> [Color] {
        let phase = sin(date.timeIntervalSinceReferenceDate * 0.8)
        let phase2 = cos(date.timeIntervalSinceReferenceDate * 0.5)

        return [
            colors[0].opacity(0.4 + 0.15 * phase),
            colors[1].opacity(0.35 + 0.15 * phase2),
            colors[2].opacity(0.3 + 0.12 * phase),
            colors[3].opacity(0.25 + 0.1 * phase2),
            colors[0].opacity(0.2 + 0.1 * phase)
        ]
    }
}
