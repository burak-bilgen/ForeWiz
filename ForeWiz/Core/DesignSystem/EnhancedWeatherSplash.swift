import SwiftUI

// MARK: - Enhanced Weather Splash Kind
enum EnhancedWeatherSplashKind: String, CaseIterable {
    case sunny, rainy, snowy, stormy, cloudy, foggy, windy, nightClear
    
    static func from(symbolName: String) -> EnhancedWeatherSplashKind {
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
    
    var displayName: String {
        switch self {
        case .sunny: return L10n.text("weather_clear")
        case .rainy: return L10n.text("weather_rain")
        case .snowy: return L10n.text("weather_snow")
        case .stormy: return L10n.text("weather_storm")
        case .cloudy: return L10n.text("weather_cloudy")
        case .foggy: return L10n.text("weather_foggy")
        case .windy: return L10n.text("weather_windy")
        case .nightClear: return L10n.text("weather_clear_night")
        }
    }
    
    var accentColors: [Color] {
        switch self {
        case .sunny:
            return [
                Color(red: 1.0, green: 0.85, blue: 0.0),
                Color(red: 1.0, green: 0.55, blue: 0.0),
                Color(red: 1.0, green: 0.95, blue: 0.4),
                Color(red: 1.0, green: 0.7, blue: 0.2)
            ]
        case .rainy:
            return [
                Color(red: 0.2, green: 0.45, blue: 0.9),
                Color(red: 0.35, green: 0.65, blue: 1.0),
                Color(red: 0.15, green: 0.35, blue: 0.75),
                Color(red: 0.5, green: 0.75, blue: 1.0)
            ]
        case .snowy:
            return [
                Color(red: 0.85, green: 0.95, blue: 1.0),
                Color(red: 0.7, green: 0.85, blue: 1.0),
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.6, green: 0.8, blue: 0.95)
            ]
        case .stormy:
            return [
                Color(red: 0.4, green: 0.15, blue: 0.7),
                Color(red: 0.7, green: 0.35, blue: 1.0),
                Color(red: 0.25, green: 0.1, blue: 0.5),
                Color(red: 0.9, green: 0.5, blue: 0.2)
            ]
        case .cloudy:
            return [
                Color(red: 0.65, green: 0.7, blue: 0.8),
                Color(red: 0.5, green: 0.55, blue: 0.65),
                Color(red: 0.8, green: 0.82, blue: 0.88),
                Color(red: 0.4, green: 0.45, blue: 0.55)
            ]
        case .foggy:
            return [
                Color(red: 0.7, green: 0.72, blue: 0.78),
                Color(red: 0.55, green: 0.6, blue: 0.68),
                Color(red: 0.85, green: 0.85, blue: 0.88),
                Color(red: 0.45, green: 0.5, blue: 0.58)
            ]
        case .windy:
            return [
                Color(red: 0.3, green: 0.65, blue: 0.95),
                Color(red: 0.6, green: 0.85, blue: 1.0),
                Color(red: 0.2, green: 0.5, blue: 0.8),
                Color(red: 0.75, green: 0.9, blue: 1.0)
            ]
        case .nightClear:
            return [
                Color(red: 0.9, green: 0.85, blue: 0.5),
                Color(red: 0.15, green: 0.2, blue: 0.5),
                Color(red: 0.25, green: 0.35, blue: 0.7),
                Color(red: 1.0, green: 0.95, blue: 0.7)
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.heavyrain.fill"
        case .snowy: return "snowflake"
        case .stormy: return "cloud.bolt.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .nightClear: return "moon.stars.fill"
        }
    }
    
    var secondaryIcon: String? {
        switch self {
        case .sunny: return "sun.haze.fill"
        case .rainy: return "drop.fill"
        case .snowy: return "cloud.snow.fill"
        case .stormy: return "bolt.fill"
        case .cloudy: return "cloud.sun.fill"
        case .foggy: return " humidity.fill"
        case .windy: return "arrow.left.arrow.right"
        case .nightClear: return "sparkles"
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

// MARK: - Enhanced Splash Overlay
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
            // Dynamic gradient background
            WeatherSplashGradientBackground(colors: kind.accentColors, opacity: opacity)
            
            // Enhanced particle effects
            EnhancedWeatherParticles(kind: kind, progress: particlesOpacity)
            
            // Central glow effect
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
            
            // Main icon with effects
            VStack(spacing: 20) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(kind.accentColors[0].opacity(glowOpacity * 0.6), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                    
                    // Secondary orbiting icon
                    if let secondary = kind.secondaryIcon {
                        Image(systemName: secondary)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(kind.accentColors[2])
                            .opacity(iconOpacity * 0.7)
                            .offset(x: 70, y: 0)
                            .rotationEffect(.degrees(iconRotation * 0.5))
                    }
                    
                    // Main icon
                    Image(systemName: kind.icon)
                        .font(.system(size: 80, weight: .medium))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(kind.accentColors[0])
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .rotationEffect(.degrees(iconRotation))
                        .shadow(color: kind.accentColors[0].opacity(0.8), radius: 40, x: 0, y: 0)
                    
                    // Inner pulse
                    Circle()
                        .fill(kind.accentColors[1].opacity(0.2 * glowOpacity))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                }
                .frame(width: 160, height: 160)
                
                // Weather label
                Text(kind.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .shadow(color: kind.accentColors[0].opacity(0.5), radius: 10)
            }
        }
        .allowsHitTesting(false)
        .onAppear { 
            runAnimation()
        }
    }
    
    private func runAnimation() {
        // Haptic feedback
        Task { @MainActor in
            switch kind.hapticStyle {
            case .light: HapticEngine.shared.light()
            case .medium: HapticEngine.shared.medium()
            case .heavy: HapticEngine.shared.heavy()
            }
        }
        
        // Background fade in
        withAnimation(.easeOut(duration: fadeInDuration)) {
            opacity = 1.0
        }
        
        // Glow fade in
        withAnimation(.easeInOut(duration: 0.4).delay(0.1)) {
            glowOpacity = 1.0
        }
        
        // Icon entrance with spring
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.15)) {
            iconScale = 1.0
            iconOpacity = 1.0
            iconRotation = 0
        }
        
        // Particles fade in
        withAnimation(.easeIn(duration: 0.5).delay(0.25)) {
            particlesOpacity = 1.0
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            textOpacity = 1.0
        }
        
        // Pulsing animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(0.6)) {
            pulseScale = 1.15
        }
        
        // Exit animations
        DispatchQueue.main.asyncAfter(deadline: .now() + iconHoldDuration) {
            // Fade out text first
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 0.0
            }
            
            // Scale up and fade icon
            withAnimation(.easeIn(duration: 0.5)) {
                iconScale = 1.5
                iconOpacity = 0.0
                glowOpacity = 0.0
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

// MARK: - Animated Gradient Background
struct WeatherSplashGradientBackground: View {
    let colors: [Color]
    let opacity: Double
    
    @State private var animateGradient = false
    
    @State private var gradientPhase: Double = 0
    
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

// MARK: - Enhanced Weather Particles
struct EnhancedWeatherParticles: View {
    let kind: EnhancedWeatherSplashKind
    let progress: Double
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: progress <= 0)) { timeline in
                Canvas { context, size in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    drawEnhancedParticles(context: context, size: size, elapsed: elapsed)
                }
            }
        }
        .opacity(progress)
        .ignoresSafeArea()
    }
    
    private func drawEnhancedParticles(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        switch kind {
        case .sunny:
            drawEnhancedSunEffects(context: context, size: size, elapsed: elapsed)
        case .rainy:
            drawEnhancedRain(context: context, size: size, elapsed: elapsed)
        case .snowy:
            drawEnhancedSnow(context: context, size: size, elapsed: elapsed)
        case .stormy:
            drawEnhancedStorm(context: context, size: size, elapsed: elapsed)
        case .cloudy:
            drawEnhancedClouds(context: context, size: size, elapsed: elapsed)
        case .foggy:
            drawEnhancedFog(context: context, size: size, elapsed: elapsed)
        case .windy:
            drawEnhancedWind(context: context, size: size, elapsed: elapsed)
        case .nightClear:
            drawEnhancedStars(context: context, size: size, elapsed: elapsed)
        }
    }
    
    private func drawEnhancedSunEffects(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let cx = size.width / 2
        let cy = size.height / 2
        
        // Rotating sun rays with varying lengths
        let rayCount = 16
        let baseAngle = elapsed * 0.3
        
        for i in 0..<rayCount {
            let angle = baseAngle + (Double(i) / Double(rayCount)) * .pi * 2
            let innerRadius: CGFloat = 50
            let outerRadius = min(size.width, size.height) * (0.4 + 0.1 * sin(elapsed * 1.5 + Double(i) * 0.3))
            let pulse = 0.8 + 0.2 * sin(elapsed * 2.0 + Double(i) * 0.4)
            
            let startX = cx + cos(angle) * innerRadius
            let startY = cy + sin(angle) * innerRadius
            let endX = cx + cos(angle) * outerRadius * pulse
            let endY = cy + sin(angle) * outerRadius * pulse
            
            var path = Path()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addLine(to: CGPoint(x: endX, y: endY))
            
            let opacity = 0.15 + 0.08 * sin(elapsed * 1.2 + Double(i))
            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 3 + 2 * CGFloat(sin(elapsed + Double(i)))
            )
        }
        
        // Floating sparkles
        let sparkleCount = 25
        for i in 0..<sparkleCount {
            let seed = Double(i) * 3.7
            let angle = seed + elapsed * 0.3
            let radius: CGFloat = 100 + CGFloat(i % 6) * 40
            let x = cx + cos(angle) * radius + sin(elapsed * 0.8 + seed) * 30
            let y = cy + sin(angle) * radius + cos(elapsed * 0.6 + seed) * 30
            let sparkleSize: CGFloat = 2 + CGFloat(i % 4)
            let opacity = 0.4 + 0.3 * sin(elapsed * 2.0 + seed)
            
            let rect = CGRect(x: x - sparkleSize/2, y: y - sparkleSize/2, width: sparkleSize, height: sparkleSize)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }
    
    private func drawEnhancedRain(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 80
        
        for i in 0..<count {
            let seed = Double(i) * 1.618
            let baseX = (seed * 97.1).truncatingRemainder(dividingBy: size.width)
            let speed: CGFloat = 400 + CGFloat(i % 5) * 100
            let dropLength: CGFloat = 15 + CGFloat(i % 4) * 8
            
            let y = CGFloat(elapsed * Double(speed) + seed * 300).truncatingRemainder(dividingBy: Double(size.height + 100)) - 50
            let x = baseX + sin(elapsed * 0.3 + seed) * 8
            
            let opacity = 0.2 + 0.15 * sin(elapsed + seed)
            
            // Rain streak with gradient effect
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + sin(elapsed + seed) * 2, y: y + dropLength))
            
            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 1.5
            )
            
            // Droplet splash at bottom
            if y > size.height - 20 {
                let splashSize: CGFloat = 4 + CGFloat(i % 3) * 2
                let splashRect = CGRect(x: x - splashSize/2, y: size.height - 5, width: splashSize, height: splashSize/2)
                context.fill(
                    Path(ellipseIn: splashRect),
                    with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity * 0.7))
                )
            }
        }
    }
    
    private func drawEnhancedSnow(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 50
        
        for i in 0..<count {
            let seed = Double(i) * 2.317
            let baseX = (seed * 73.7).truncatingRemainder(dividingBy: Double(size.width))
            let speed: CGFloat = 40 + CGFloat(i % 5) * 20
            let wobbleAmp: CGFloat = 30 + CGFloat(i % 4) * 20
            let wobbleFreq = 0.6 + Double(i % 6) * 0.25
            
            let baseY = CGFloat(elapsed * Double(speed) + seed * 500).truncatingRemainder(dividingBy: Double(size.height + 60)) - 30
            let wobbleX = sin(elapsed * wobbleFreq + seed) * wobbleAmp + cos(elapsed * 0.4 + seed) * 10
            let x = baseX + wobbleX
            
            let opacity = 0.35 + 0.2 * sin(elapsed * 1.2 + seed)
            let flakeSize: CGFloat = 3 + CGFloat(i % 5) * 2
            
            // Snowflake with six points
            let center = CGPoint(x: x, y: baseY)
            for j in 0..<6 {
                let rayAngle = Double(j) * .pi / 3 + elapsed * 0.2 * (i % 2 == 0 ? 1 : -1)
                let rayLength = flakeSize * 1.5
                var ray = Path()
                ray.move(to: center)
                ray.addLine(to: CGPoint(
                    x: center.x + cos(rayAngle) * rayLength,
                    y: center.y + sin(rayAngle) * rayLength
                ))
                context.stroke(
                    ray,
                    with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                    lineWidth: 1
                )
            }
            
            // Center dot
            let rect = CGRect(x: x - flakeSize/3, y: baseY - flakeSize/3, width: flakeSize/1.5, height: flakeSize/1.5)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }
    
    private func drawEnhancedStorm(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        // Lightning flash
        let flashCycle = elapsed.truncatingRemainder(dividingBy: 2.0)
        if flashCycle < 0.08 {
            let flashOpacity: Double = 0.4 - flashCycle * 5.0
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .color(Color.white.opacity(max(0, flashOpacity)))
            )
        }
        
        // Jagged lightning bolt
        if flashCycle < 0.15 {
            let boltOpacity = 0.8 - flashCycle * 5.0
            let startX = size.width * 0.3 + CGFloat(sin(elapsed) * 50)
            var bolt = Path()
            bolt.move(to: CGPoint(x: startX, y: 0))
            
            var currentX = startX
            var currentY: CGFloat = 0
            while currentY < size.height {
                currentX += CGFloat(sin(elapsed * 10 + Double(currentY)) * 30)
                currentY += 20
                bolt.addLine(to: CGPoint(x: currentX, y: currentY))
            }
            
            context.stroke(
                bolt,
                with: .color(Color.white.opacity(max(0, boltOpacity))),
                lineWidth: 3
            )
        }
        
        // Heavy rain
        drawEnhancedRain(context: context, size: size, elapsed: elapsed * 1.5)
    }
    
    private func drawEnhancedClouds(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 12
        
        for i in 0..<count {
            let seed = Double(i) * 3.41
            let baseY = size.height * 0.1 + CGFloat(i % 4) * size.height * 0.15
            let speed = 20 + Double(i % 4) * 15
            let baseX = CGFloat((elapsed * speed + seed * 250).truncatingRemainder(dividingBy: Double(size.width + 400))) - 200
            
            // Multiple overlapping circles for fluffy cloud effect
            let offsets: [(CGFloat, CGFloat, CGFloat)] = [
                (0, 0, 60), (40, -10, 50), (-35, 5, 45), (20, 15, 40), (-20, -15, 35)
            ]
            
            for (ox, oy, radius) in offsets {
                let x = baseX + ox + sin(elapsed * 0.2 + seed) * 10
                let y = baseY + oy
                let opacity = 0.06 + 0.04 * sin(elapsed * 0.4 + seed + Double(ox))
                
                let rect = CGRect(
                    x: x - radius,
                    y: y - radius/2,
                    width: radius * 2,
                    height: radius
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
                )
            }
        }
    }
    
    private func drawEnhancedFog(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 15
        
        for i in 0..<count {
            let seed = Double(i) * 4.23
            let baseY = size.height * 0.15 + CGFloat(i % 5) * size.height * 0.16
            let drift = sin(elapsed * 0.15 + seed) * 50 + cos(elapsed * 0.1 + seed) * 30
            let baseX = (seed * 127.3).truncatingRemainder(dividingBy: Double(size.width)) + drift
            
            let patchWidth: CGFloat = 150 + CGFloat(i % 4) * 80
            let patchHeight: CGFloat = 50 + CGFloat(i % 3) * 25
            let opacity = 0.08 + 0.05 * sin(elapsed * 0.25 + seed)
            
            // Layered fog patches
            for layer in 0..<3 {
                let layerOffset = CGFloat(layer) * 20
                let layerOpacity = opacity * (1.0 - Double(layer) * 0.3)
                
                let rect = CGRect(
                    x: baseX - patchWidth / 2 + layerOffset,
                    y: baseY - patchHeight / 2 + sin(elapsed + seed + Double(layer)) * 10,
                    width: patchWidth,
                    height: patchHeight
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(kind.accentColors[i % kind.accentColors.count].opacity(layerOpacity))
                )
            }
        }
    }
    
    private func drawEnhancedWind(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 35
        
        for i in 0..<count {
            let seed = Double(i) * 1.73
            let baseY = (seed * 89.3).truncatingRemainder(dividingBy: Double(size.height))
            let speed = 250 + Double(i % 5) * 100
            let streakX = CGFloat((elapsed * speed + seed * 180).truncatingRemainder(dividingBy: Double(size.width + 300))) - 150
            let streakLength: CGFloat = 60 + CGFloat(i % 4) * 40
            let streakCurve = sin(elapsed * 2 + seed) * 10
            
            let opacity = 0.15 + 0.08 * sin(elapsed * 1.5 + seed)
            
            // Curved wind streak
            var path = Path()
            path.move(to: CGPoint(x: streakX, y: baseY))
            path.addCurve(
                to: CGPoint(x: streakX + streakLength, y: baseY + streakCurve),
                control1: CGPoint(x: streakX + streakLength/3, y: baseY - streakCurve/2),
                control2: CGPoint(x: streakX + streakLength*2/3, y: baseY + streakCurve*1.5)
            )
            
            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 2
            )
            
            // Wind particles
            if i % 3 == 0 {
                let particleX = streakX + streakLength + sin(elapsed * 3 + seed) * 20
                let particleY = baseY + streakCurve
                let rect = CGRect(x: particleX - 2, y: particleY - 2, width: 4, height: 4)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity * 1.5))
                )
            }
        }
    }
    
    private func drawEnhancedStars(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 60
        
        for i in 0..<count {
            let seed = Double(i) * 7.91
            let x = (seed * 113.7).truncatingRemainder(dividingBy: Double(size.width))
            let y = (seed * 59.3).truncatingRemainder(dividingBy: Double(size.height))
            let starSize: CGFloat = 1.5 + CGFloat(i % 4)
            
            // Twinkle effect with varying speeds
            let twinkleSpeed = 1.0 + Double(i % 5) * 0.5
            let twinkle = 0.25 + 0.55 * abs(sin(elapsed * twinkleSpeed + seed))
            let color = kind.accentColors[i % kind.accentColors.count]
            
            // Draw 4-pointed star
            let center = CGPoint(x: x, y: y)
            for j in 0..<4 {
                let angle = Double(j) * .pi / 2
                let length = starSize * (1.5 + 0.5 * sin(elapsed * 2 + seed))
                var ray = Path()
                ray.move(to: center)
                ray.addLine(to: CGPoint(
                    x: center.x + cos(angle) * length,
                    y: center.y + sin(angle) * length
                ))
                context.stroke(
                    ray,
                    with: .color(color.opacity(twinkle)),
                    lineWidth: 1
                )
            }
            
            // Center glow for brighter stars
            if i % 4 == 0 {
                let glowSize = starSize * 3
                let glowRect = CGRect(x: x - glowSize/2, y: y - glowSize/2, width: glowSize, height: glowSize)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(color.opacity(twinkle * 0.2))
                )
            }
            
            // Occasional shooting star
            if i % 15 == 0 {
                let shootPhase = elapsed.truncatingRemainder(dividingBy: 3.0)
                if shootPhase < 0.5 {
                    let shootX = x + shootPhase * 200
                    let shootY = y + shootPhase * 100
                    var trail = Path()
                    trail.move(to: CGPoint(x: shootX, y: shootY))
                    trail.addLine(to: CGPoint(x: shootX - 30, y: shootY - 15))
                    context.stroke(
                        trail,
                        with: .color(Color.white.opacity(1.0 - shootPhase * 2)),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}
