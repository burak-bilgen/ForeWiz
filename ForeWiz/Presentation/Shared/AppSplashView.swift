import Combine
import SwiftUI

struct AppSplashView: View {
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowPulse = false

    private let sky = Color(red: 0.35, green: 0.68, blue: 1.0)

    var body: some View {
        ZStack {
            AnimatedOrbBackground(
                primary:   Color(red: 0.25, green: 0.50, blue: 1.00),
                secondary: Color(red: 0.55, green: 0.30, blue: 1.00),
                tertiary:  Color(red: 0.20, green: 0.75, blue: 0.90)
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(sky.opacity(glowPulse ? 0.18 : 0.08))
                        .frame(width: 120, height: 120)
                        .blur(radius: 24)
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 96, height: 96)

                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(sky)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: 10) {
                    Text("ForeWiz")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    LoadingDotsView()
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
            glowPulse = true
        }
    }
}

private struct LoadingDotsView: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(phase == i ? 0.90 : 0.25))
                    .frame(width: 6, height: 6)
                    .scaleEffect(phase == i ? 1.35 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: phase)
            }
        }
        .onReceive(Timer.publish(every: 0.38, on: .main, in: .common).autoconnect()) { _ in
            phase = (phase + 1) % 3
        }
    }
}
