import SwiftUI

// MARK: - Liquid Glass Splash View
struct AppSplashView: View {
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .default)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(AppTheme.liquidAccent.opacity(glowPulse ? 0.18 : 0.08))
                        .frame(width: 130, height: 130)
                        .blur(radius: 28)
                        .animation(AppTheme.pulseEaseOut.repeatForever(autoreverses: true), value: glowPulse)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.08), lineWidth: 0.5)
                        )

                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 46, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.liquidAccent)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: 12) {
                    Text(L10n.text("splash_app_name"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    PulsingDotsLoader(color: .white.opacity(0.6), dotSize: 7)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(AppTheme.sheetSpring) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(AppTheme.defaultEaseOut.delay(0.3)) {
                textOpacity = 1.0
            }
            glowPulse = true
        }
    }
}
