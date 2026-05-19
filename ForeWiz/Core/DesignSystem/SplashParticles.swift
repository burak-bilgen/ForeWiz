import SwiftUI

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
        case .sunny:        drawEnhancedSunEffects(context: context, size: size, elapsed: elapsed)
        case .rainy:        drawEnhancedRain(context: context, size: size, elapsed: elapsed)
        case .snowy:        drawEnhancedSnow(context: context, size: size, elapsed: elapsed)
        case .stormy:       drawEnhancedStorm(context: context, size: size, elapsed: elapsed)
        case .cloudy:       drawEnhancedClouds(context: context, size: size, elapsed: elapsed)
        case .foggy:        drawEnhancedFog(context: context, size: size, elapsed: elapsed)
        case .windy:        drawEnhancedWind(context: context, size: size, elapsed: elapsed)
        case .nightClear:   drawEnhancedStars(context: context, size: size, elapsed: elapsed)
        }
    }

    private func drawEnhancedSunEffects(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let cx = size.width / 2
        let cy = size.height / 2

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

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + sin(elapsed + seed) * 2, y: y + dropLength))

            context.stroke(
                path,
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity)),
                lineWidth: 1.5
            )

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

            let rect = CGRect(x: x - flakeSize/3, y: baseY - flakeSize/3, width: flakeSize/1.5, height: flakeSize/1.5)
            context.fill(
                Path(ellipseIn: rect),
                with: .color(kind.accentColors[i % kind.accentColors.count].opacity(opacity))
            )
        }
    }

    private func drawEnhancedStorm(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let flashCycle = elapsed.truncatingRemainder(dividingBy: 2.0)
        if flashCycle < 0.08 {
            let flashOpacity: Double = 0.4 - flashCycle * 5.0
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .color(Color.white.opacity(max(0, flashOpacity)))
            )
        }

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

        drawEnhancedRain(context: context, size: size, elapsed: elapsed * 1.5)
    }

    private func drawEnhancedClouds(context: GraphicsContext, size: CGSize, elapsed: TimeInterval) {
        let count = 12

        for i in 0..<count {
            let seed = Double(i) * 3.41
            let baseY = size.height * 0.1 + CGFloat(i % 4) * size.height * 0.15
            let speed = 20 + Double(i % 4) * 15
            let baseX = CGFloat((elapsed * speed + seed * 250).truncatingRemainder(dividingBy: Double(size.width + 400))) - 200

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

            let twinkleSpeed = 1.0 + Double(i % 5) * 0.5
            let twinkle = 0.25 + 0.55 * abs(sin(elapsed * twinkleSpeed + seed))
            let color = kind.accentColors[i % kind.accentColors.count]

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

            if i % 4 == 0 {
                let glowSize = starSize * 3
                let glowRect = CGRect(x: x - glowSize/2, y: y - glowSize/2, width: glowSize, height: glowSize)
                context.fill(
                    Path(ellipseIn: glowRect),
                    with: .color(color.opacity(twinkle * 0.2))
                )
            }

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
