import SwiftUI

enum WeatherSplashKind {
    case sunny
    case rainy
    case snowy
    case stormy
    case cloudy
    case foggy
    case windy
    case nightClear

    static func from(symbolName: String) -> WeatherSplashKind {
        let s = symbolName.lowercased()
        if s.contains("storm") || s.contains("thunder") || s.contains("bolt") { return .stormy }
        if s.contains("snow") || s.contains("sleet") || s.contains("flurry") { return .snowy }
        if s.contains("rain") || s.contains("drizzle") || s.contains("shower") { return .rainy }
        if s.contains("fog") || s.contains("mist") || s.contains("haze") { return .foggy }
        if s.contains("wind") { return .windy }
        if s.contains("cloud") { return .cloudy }
        if s.contains("moon") || s.contains("night") { return .nightClear }
        return .sunny
    }

    var accentColors: [Color] {
        switch self {
        case .sunny:
            return [Color(red: 1.0, green: 0.75, blue: 0.2), Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 1.0, green: 0.85, blue: 0.4)]
        case .rainy:
            return [Color(red: 0.3, green: 0.55, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 0.75), Color(red: 0.5, green: 0.7, blue: 1.0)]
        case .snowy:
            return [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.85, green: 0.9, blue: 1.0), Color(red: 0.6, green: 0.75, blue: 0.95)]
        case .stormy:
            return [Color(red: 0.55, green: 0.25, blue: 0.85), Color(red: 0.75, green: 0.4, blue: 1.0), Color(red: 0.35, green: 0.15, blue: 0.6)]
        case .cloudy:
            return [Color(red: 0.55, green: 0.6, blue: 0.7), Color(red: 0.45, green: 0.5, blue: 0.6), Color(red: 0.65, green: 0.7, blue: 0.78)]
        case .foggy:
            return [Color(red: 0.6, green: 0.65, blue: 0.72), Color(red: 0.7, green: 0.72, blue: 0.75), Color(red: 0.5, green: 0.55, blue: 0.62)]
        case .windy:
            return [Color(red: 0.4, green: 0.72, blue: 1.0), Color(red: 0.6, green: 0.82, blue: 1.0), Color(red: 0.3, green: 0.6, blue: 0.85)]
        case .nightClear:
            return [Color(red: 0.15, green: 0.2, blue: 0.45), Color(red: 0.25, green: 0.3, blue: 0.6), Color(red: 0.9, green: 0.85, blue: 0.6)]
        }
    }

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "cloud.bolt.rain.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .nightClear: return "moon.stars.fill"
        }
    }

    var hapticStyle: HapticStyle {
        switch self {
        case .sunny: return .light
        case .cloudy: return .light
        case .foggy: return .light
        case .nightClear: return .light
        case .windy: return .medium
        case .rainy: return .medium
        case .snowy: return .medium
        case .stormy: return .heavy
        }
    }

    enum HapticStyle {
        case light, medium, heavy
    }
}

struct WeatherSplashOverlay: View {
    let kind: WeatherSplashKind
    let onDismiss: () -> Void
    var onFadeOut: (() -> Void)?

    @State private var opacity = 0.0
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0.0
    @State private var particlesOpacity: Double = 0.0
    @State private var dismissed = false

    private let totalDuration: Double = 2.0
    private let fadeInDuration: Double = 0.4
    private let fadeOutDuration: Double = 0.8
    private let iconHoldDuration: Double = 1.2

    var body: some View {
        ZStack {
            Color.black
                .opacity(opacity * 0.4)

            WeatherSplashParticles(kind: kind, progress: particlesOpacity)

            VStack(spacing: 16) {
                Image(systemName: kind.icon)
                    .font(.system(size: 96, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(kind.accentColors.first ?? .white)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .shadow(color: (kind.accentColors.first ?? .white).opacity(0.6), radius: 30)
            }
        }
        .allowsHitTesting(false)
        .onAppear { runAnimation() }
    }

    @MainActor
    private func runAnimation() {
        switch kind.hapticStyle {
        case .light: HapticEngine.shared.light()
        case .medium: HapticEngine.shared.medium()
        case .heavy: HapticEngine.shared.heavy()
        }

        withAnimation(.easeOut(duration: fadeInDuration)) {
            opacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        withAnimation(.easeIn(duration: 0.3).delay(0.15)) {
            particlesOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + iconHoldDuration) {
            withAnimation(.easeOut(duration: 0.5)) {
                iconScale = 1.4
                iconOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - fadeOutDuration) {
            onFadeOut?()
            withAnimation(.easeOut(duration: fadeOutDuration)) {
                opacity = 0.0
                particlesOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            dismissed = true
            onDismiss()
        }
    }
}

private struct WeatherSplashParticles: View {
    let kind: WeatherSplashKind
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: progress <= 0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    drawParticles(context: context, size: size, elapsed: elapsed)
                }
            }
        }
        .opacity(progress)
        .ignoresSafeArea()
    }

    private func drawParticles(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        switch kind {
        case .sunny:
            drawSunRays(context: context, size: size, elapsed: elapsed)
            drawSunParticles(context: context, size: size, elapsed: elapsed)
        case .rainy:
            drawRaindrops(context: context, size: size, elapsed: elapsed)
        case .snowy:
            drawSnowflakes(context: context, size: size, elapsed: elapsed)
        case .stormy:
            drawLightning(context: context, size: size, elapsed: elapsed)
            drawRaindrops(context: context, size: size, elapsed: elapsed)
        case .cloudy:
            drawCloudPuffs(context: context, size: size, elapsed: elapsed)
        case .foggy:
            drawFogPatches(context: context, size: size, elapsed: elapsed)
        case .windy:
            drawWindStreaks(context: context, size: size, elapsed: elapsed)
        case .nightClear:
            drawStars(context: context, size: size, elapsed: elapsed)
        }
    }

    private func drawSunRays(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let cx = size.width / 2
        let cy = size.height / 2
        let rayCount = 12
        let baseAngle = elapsed * 0.4

        for i in 0..<rayCount {
            let angle = baseAngle + (Double(i) / Double(rayCount)) * .pi * 2
            let innerRadius: CGFloat = 40
            let outerRadius: CGFloat = min(size.width, size.height) * 0.5
            let pulse = 0.85 + 0.15 * sin(elapsed * 2.0 + Double(i) * 0.5)

            let startX = cx + cos(angle) * innerRadius
            let startY = cy + sin(angle) * innerRadius
            let endX = cx + cos(angle) * outerRadius * pulse
            let endY = cy + sin(angle) * outerRadius * pulse

            var path = Path()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))

            let opacity = 0.12 + 0.06 * sin(elapsed * 1.5 + Double(i))
            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 4
            )
        }
    }

    private func drawSunParticles(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let cx = size.width / 2
        let cy = size.height / 2
        let count = 30

        for i in 0..<count {
            let baseAngle = Double(i) / Double(count) * .pi * 2
            let angle = baseAngle + elapsed * 0.25
            let baseRadius: CGFloat = 80 + CGFloat(i % 5) * 40
            let drift = sin(elapsed * 0.8 + Double(i) * 0.7) * 20
            let radius = baseRadius + drift

            let x = cx + cos(angle) * radius
            let y = cy + sin(angle) * radius
            let particleSize: CGFloat = 3 + CGFloat(i % 3) * 2
            let opacity = 0.25 + 0.15 * sin(elapsed * 2.0 + Double(i))

            let rect = CGRect(x: x - particleSize / 2, y: y - particleSize / 2, width: particleSize, height: particleSize)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }

    private func drawRaindrops(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 60

        for i in 0..<count {
            let seed = Double(i) * 1.618
            let baseX = (seed * 97.1).truncatingRemainder(dividingBy: size.width)
            let speed: CGFloat = 300 + CGFloat(i % 4) * 80
            let dropLength: CGFloat = 12 + CGFloat(i % 3) * 6
            let dropWidth: CGFloat = 1.5

            let y = CGFloat(elapsed * Double(speed) + Double(seed * 200)).truncatingRemainder(dividingBy: Double(size.height + 100)) - 50
            let x = baseX + sin(elapsed * 0.5 + seed) * 5

            let opacity = 0.15 + 0.1 * sin(elapsed + seed)

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + 1, y: y + dropLength))

            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: dropWidth
            )
        }
    }

    private func drawSnowflakes(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 40

        for i in 0..<count {
            let seed = Double(i) * 2.317
            let baseX = (seed * 73.7).truncatingRemainder(dividingBy: Double(size.width))
            let speed: CGFloat = 30 + CGFloat(i % 4) * 15
            let wobbleAmp: CGFloat = 25 + CGFloat(i % 3) * 15
            let wobbleFreq = 0.8 + Double(i % 5) * 0.2
            let flakeSize: CGFloat = 3 + CGFloat(i % 4) * 2

            let baseY = CGFloat(elapsed * Double(speed) + seed * 500).truncatingRemainder(dividingBy: Double(size.height + 60)) - 30
            let wobbleX = sin(elapsed * wobbleFreq + seed) * wobbleAmp
            let x = baseX + wobbleX

            let opacity = 0.25 + 0.15 * sin(elapsed * 1.5 + seed)

            let rect = CGRect(x: x - flakeSize / 2, y: baseY - flakeSize / 2, width: flakeSize, height: flakeSize)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }

    private func drawLightning(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let flashCycle = elapsed.truncatingRemainder(dividingBy: 2.5)
        if flashCycle < 0.12 {
            let flashOpacity: Double = 0.25 - flashCycle * 2.0
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .color(Color.white.opacity(max(0, flashOpacity)))
            )
        }
    }

    private func drawCloudPuffs(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 8

        for i in 0..<count {
            let seed = Double(i) * 3.41
            let baseY = size.height * 0.15 + CGFloat(i % 3) * size.height * 0.2
            let speed = 15 + Double(i % 3) * 10
            let baseX = CGFloat((elapsed * speed + seed * 200).truncatingRemainder(dividingBy: Double(size.width + 300))) - 150
            let puffWidth: CGFloat = 80 + CGFloat(i % 3) * 40
            let puffHeight: CGFloat = 35 + CGFloat(i % 2) * 15
            let opacity = 0.08 + 0.04 * sin(elapsed * 0.5 + seed)

            let rect = CGRect(
                x: baseX - puffWidth / 2,
                y: baseY - puffHeight / 2,
                width: puffWidth,
                height: puffHeight
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }

    private func drawFogPatches(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 10

        for i in 0..<count {
            let seed = Double(i) * 4.23
            let baseY = size.height * 0.2 + CGFloat(i % 4) * size.height * 0.18
            let drift = sin(elapsed * 0.2 + seed) * 40
            let baseX = (seed * 127.3).truncatingRemainder(dividingBy: Double(size.width)) + drift
            let patchWidth: CGFloat = 120 + CGFloat(i % 3) * 60
            let patchHeight: CGFloat = 40 + CGFloat(i % 2) * 20
            let opacity = 0.06 + 0.03 * sin(elapsed * 0.3 + seed)

            let rect = CGRect(
                x: baseX - patchWidth / 2,
                y: baseY - patchHeight / 2,
                width: patchWidth,
                height: patchHeight
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }

    private func drawWindStreaks(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 25

        for i in 0..<count {
            let seed = Double(i) * 1.73
            let baseY = (seed * 89.3).truncatingRemainder(dividingBy: Double(size.height))
            let speed = 200 + Double(i % 4) * 80
            let streakX = CGFloat((elapsed * speed + seed * 150).truncatingRemainder(dividingBy: Double(size.width + 200))) - 100
            let streakLength: CGFloat = 40 + CGFloat(i % 3) * 30
            let opacity = 0.12 + 0.06 * sin(elapsed * 2.0 + seed)

            var path = Path()
            path.move(to: CGPoint(x: streakX, y: baseY))
            path.addLine(to: CGPoint(x: streakX + streakLength, y: baseY + sin(elapsed * 3 + seed) * 3))

            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 1.5
            )
        }
    }

    private func drawStars(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 50

        for i in 0..<count {
            let seed = Double(i) * 7.91
            let x = (seed * 113.7).truncatingRemainder(dividingBy: Double(size.width))
            let y = (seed * 59.3).truncatingRemainder(dividingBy: Double(size.height))
            let starSize: CGFloat = 2 + CGFloat(i % 3)
            let twinkle = 0.3 + 0.5 * abs(sin(elapsed * (1.5 + Double(i % 4) * 0.5) + seed))
            let color = kind.accentColors[i % kind.accentColors.count]

            let rect = CGRect(x: x - starSize / 2, y: y - starSize / 2, width: starSize, height: starSize)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(color.opacity(twinkle))
            )

            if i % 5 == 0 {
                let glowSize = starSize * 4
                let glowRect = CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(color.opacity(twinkle * 0.15))
                )
            }
        }
    }
}