import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)

    let colors: [Color]
    let animationDuration: Double

    init(colors: [Color] = [.blue, .purple, .pink], animationDuration: Double = 8) {
        self.colors = colors
        self.animationDuration = animationDuration
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: start,
            endPoint: end
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                start = UnitPoint(x: 1, y: 1)
                end = UnitPoint(x: 0, y: 0)
            }
        }
    }
}

struct AnimatedMeshGradient: View {
    @State private var phase: CGFloat = 0

    let colors: [Color]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
            Canvas { context, size in
                let width = Int(size.width)
                let height = Int(size.height)

                for x in stride(from: 0, to: width, by: 10) {
                    for y in stride(from: 0, to: height, by: 10) {
                        let normalizedX = Double(x) / Double(width)
                        let normalizedY = Double(y) / Double(height)

                        let noise = sin(normalizedX * 4 + phase) * cos(normalizedY * 4 + phase)
                        let colorIndex = Int((noise + 1) / 2 * Double(colors.count - 1))
                        let safeIndex = max(0, min(colorIndex, colors.count - 1))

                        let rect = CGRect(x: x, y: y, width: 10, height: 10)
                        context.fill(Path(rect), with: .color(colors[safeIndex].opacity(0.3)))
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                phase += 0.02
            }
        }
    }
}

struct ParticleEffect: ViewModifier {
    @State private var particles: [Particle] = []
    let particleCount: Int
    let particleColor: Color
    let speed: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x * size.width,
                            y: particle.y * size.height,
                            width: particle.size,
                            height: particle.size
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(particleColor.opacity(particle.opacity)))
                    }
                }
            )
            .onAppear {
                particles = (0..<particleCount).map { _ in
                    Particle(
                        x: Double.random(in: 0...1),
                        y: Double.random(in: 0...1),
                        size: Double.random(in: 2...6),
                        opacity: Double.random(in: 0.3...0.8),
                        speedX: Double.random(in: -0.002...0.002) * speed,
                        speedY: Double.random(in: -0.005...0.005) * speed
                    )
                }

                Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
                    updateParticles()
                }
            }
    }

    private func updateParticles() {
        particles = particles.map { particle in
            var newParticle = particle
            newParticle.x += particle.speedX
            newParticle.y += particle.speedY

            if newParticle.x < 0 { newParticle.x = 1 }
            if newParticle.x > 1 { newParticle.x = 0 }
            if newParticle.y < 0 { newParticle.y = 1 }
            if newParticle.y > 1 { newParticle.y = 0 }

            return newParticle
        }
    }
}

struct Particle {
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
    var speedX: Double
    var speedY: Double
}

struct GlitchEffect: ViewModifier {
    @State private var offset: CGSize = .zero
    @State private var isGlitching = false

    let intensity: CGFloat
    let frequency: Double

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { _ in
                    glitch()
                }
            }
    }

    private func glitch() {
        guard Bool.random() else { return }

        isGlitching = true

        withAnimation(.linear(duration: 0.05)) {
            offset = CGSize(
                width: CGFloat.random(in: -intensity...intensity),
                height: CGFloat.random(in: -intensity...intensity)
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                offset = .zero
            }
            isGlitching = false
        }
    }
}

struct NeonGlowEffect: ViewModifier {
    let color: Color
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: intensity, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: intensity * 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: intensity * 3, x: 0, y: 0)
    }
}

struct BreathingEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0

    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = maxScale
                }
            }
            .onDisappear {
                scale = minScale
            }
    }
}

struct PulseRingEffect: View {
    let color: Color
    let count: Int
    let duration: Double

    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(pulse ? 1.5 : 0.5)
                    .opacity(pulse ? 0 : 1)
                    .animation(
                        .easeOut(duration: duration)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * duration / Double(count)),
                        value: pulse
                    )
            }
        }
        .onAppear {
            pulse = true
        }
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -200

    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.5),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase)
                    .blendMode(.screen)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

struct WaveEffect: View {
    let color: Color
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
            Canvas { context, size in
                var path = Path()
                let width = size.width
                let height = size.height
                let midHeight = height / 2

                path.move(to: CGPoint(x: 0, y: midHeight))

                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin(relativeX * frequency * .pi * 2 + phase + CGFloat(timeline.date.timeIntervalSince1970))
                    let y = midHeight + sine * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()

                context.fill(path, with: .color(color))
            }
        }
    }
}

struct FlipCard<Front: View, Back: View>: View {
    let front: Front
    let back: Back

    @State private var isFlipped = false
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )

            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(rotation + 180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                rotation += 180
                isFlipped.toggle()
            }
        }
    }
}

struct MagneticButton: ViewModifier {
    @State private var offset: CGSize = .zero

    let strength: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let maxOffset: CGFloat = 20
                        let x = min(max(value.translation.width * strength, -maxOffset), maxOffset)
                        let y = min(max(value.translation.height * strength, -maxOffset), maxOffset)
                        offset = CGSize(width: x, height: y)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            offset = .zero
                        }
                    }
            )
    }
}

struct ElasticScaleEffect: ViewModifier {
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                    scale = pressing ? 0.9 : 1.0
                }
            }, perform: {})
    }
}

struct LiquidShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2

        let waveHeight = height * 0.1 * progress
        let waveCount: CGFloat = 4

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, to: width, by: 10) {
            let normalizedX = x / width
            let wave = sin(normalizedX * waveCount * .pi * 2) * waveHeight
            let y = midHeight + wave
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

struct AuroraEffect: View {
    let colors: [Color]

    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: false)) { _ in
            Canvas { context, size in
                for (index, color) in colors.enumerated() {
                    var path = Path()
                    let offset = CGFloat(index) * 0.3

                    for x in stride(from: 0, to: size.width, by: 5) {
                        let normalizedX = x / size.width
                        let wave1 = sin(normalizedX * 3 + phase + offset) * 50
                        let wave2 = cos(normalizedX * 5 + phase * 0.5 + offset) * 30
                        let y = size.height * 0.5 + wave1 + wave2

                        if x == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()

                    context.fill(path, with: .color(color.opacity(0.3)))
                }
            }
            .onChange(of: phase) { _, _ in
                phase += 0.02
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                phase += 0.1
            }
        }
    }
}

struct ConfettiEffect: View {
    let colors: [Color]
    let count: Int

    @State private var pieces: [ConfettiPiece] = []
    @State private var isAnimating = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60, paused: !isAnimating)) { _ in
            Canvas { context, size in
                for piece in pieces {
                    let transform = CGAffineTransform.identity
                        .translatedBy(x: piece.x, y: piece.y)
                        .rotated(by: piece.rotation)

                    let rect = CGRect(x: -piece.size/2, y: -piece.size/2, width: piece.size, height: piece.size)
                    let path = Path(rect).applying(transform)

                    context.fill(path, with: .color(piece.color))
                }
            }
        }
        .onAppear {
            pieces = (0..<count).map { _ in
                ConfettiPiece(
                    x: Double.random(in: 0...300),
                    y: -20,
                    size: Double.random(in: 5...15),
                    color: colors.randomElement() ?? .red,
                    rotation: Double.random(in: 0...(.pi * 2)),
                    velocity: Double.random(in: 2...6),
                    rotationSpeed: Double.random(in: -0.2...0.2)
                )
            }
            isAnimating = true
            animate()
        }
    }

    private func animate() {
        Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            pieces = pieces.map { piece in
                var newPiece = piece
                newPiece.y += piece.velocity
                newPiece.rotation += piece.rotationSpeed
                newPiece.x += sin(newPiece.y * 0.02) * 2

                if newPiece.y > 600 {
                    newPiece.y = -20
                    newPiece.x = Double.random(in: 0...300)
                }

                return newPiece
            }
        }
    }
}

struct ConfettiPiece {
    var x: Double
    var y: Double
    var size: Double
    var color: Color
    var rotation: Double
    var velocity: Double
    var rotationSpeed: Double
}

extension View {
    func particleEffect(count: Int = 30, color: Color = .white, speed: Double = 1.0) -> some View {
        modifier(ParticleEffect(particleCount: count, particleColor: color, speed: speed))
    }

    func glitchEffect(intensity: CGFloat = 5, frequency: Double = 3) -> some View {
        modifier(GlitchEffect(intensity: intensity, frequency: frequency))
    }

    func neonGlow(color: Color = .cyan, intensity: CGFloat = 10) -> some View {
        modifier(NeonGlowEffect(color: color, intensity: intensity))
    }

    func breathing(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 2) -> some View {
        modifier(BreathingEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }

    func shimmerEffect(duration: Double = 1.5) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }

    func magnetic(strength: CGFloat = 0.3) -> some View {
        modifier(MagneticButton(strength: strength))
    }

    func elasticScale() -> some View {
        modifier(ElasticScaleEffect())
    }
}

struct AnimatedNumberText: View {
    let value: Int
    let duration: Double

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { _, _ in
                animateValue()
            }
    }

    private func animateValue() {
        let steps = 20
        let stepDuration = duration / Double(steps)
        let stepValue = Double(value) / Double(steps)

        for step in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                displayValue = Int(Double(step + 1) * stepValue)
            }
        }
    }
}

struct SkeletonLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray5),
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                }
                .mask(RoundedRectangle(cornerRadius: 8))
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct CountdownView: View {
    let targetDate: Date

    @State private var remainingTime: TimeInterval = 0

    var body: some View {
        HStack(spacing: 8) {
            TimeUnitView(value: hours, unit: "HRS")
            Text(":")
                .font(.title.bold())
            TimeUnitView(value: minutes, unit: "MIN")
            Text(":")
                .font(.title.bold())
            TimeUnitView(value: seconds, unit: "SEC")
        }
        .onAppear {
            updateTime()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTime()
            }
        }
    }

    private func updateTime() {
        remainingTime = max(0, targetDate.timeIntervalSinceNow)
    }

    private var hours: Int {
        Int(remainingTime) / 3600
    }

    private var minutes: Int {
        (Int(remainingTime) % 3600) / 60
    }

    private var seconds: Int {
        Int(remainingTime) % 60
    }
}

struct TimeUnitView: View {
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value))
                .font(.title2.bold())
                .monospacedDigit()
                .frame(minWidth: 50)
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)

            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct StaggeredAnimation<Content: View>: View {
    let content: Content
    let delay: Double
    @State private var isVisible = false

    init(delay: Double = 0, @ViewBuilder content: () -> Content) {
        self.delay = delay
        self.content = content()
    }

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isVisible = true
                    }
                }
            }
    }
}

extension View {
    func staggeredAnimation(delay: Double = 0) -> some View {
        StaggeredAnimation(delay: delay) { self }
    }
}
