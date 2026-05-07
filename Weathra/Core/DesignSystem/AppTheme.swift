import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.85)
    static let sky = Color(red: 0.35, green: 0.70, blue: 0.95)
    static let teal = Color(red: 0.05, green: 0.65, blue: 0.60)
    static let sunshine = Color(red: 0.98, green: 0.65, blue: 0.20)
    static let rain = Color(red: 0.30, green: 0.55, blue: 0.82)
    static let success = Color(red: 0.08, green: 0.58, blue: 0.40)
    static let warning = Color(red: 0.90, green: 0.50, blue: 0.15)
    static let danger = Color(red: 0.85, green: 0.22, blue: 0.28)

    static let ink = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)

    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemGroupedBackground)

    static let cardRadius: CGFloat = 24
    static let compactRadius: CGFloat = 16
    static let iconBubbleRadius: CGFloat = 12
    static let pillRadius: CGFloat = 20

    static func accent(for palette: AppAccentPalette) -> Color {
        switch palette {
        case .sky: return accent
        case .mint: return teal
        case .ember: return warning
        }
    }

    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color]

        switch colorScheme {
        case .dark:
            colors = [
                Color(red: 0.06, green: 0.08, blue: 0.12),
                Color(red: 0.08, green: 0.14, blue: 0.18),
                Color(red: 0.14, green: 0.14, blue: 0.16)
            ]
        case .light:
            colors = [
                Color(red: 0.93, green: 0.97, blue: 0.99),
                Color(red: 0.99, green: 0.995, blue: 0.98),
                Color(red: 0.97, green: 0.94, blue: 0.89)
            ]
        @unknown default:
            colors = [Color(uiColor: .systemGroupedBackground)]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func weatherGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color]

        switch colorScheme {
        case .dark:
            colors = [
                Color(red: 0.10, green: 0.24, blue: 0.45),
                Color(red: 0.06, green: 0.45, blue: 0.50),
                Color(red: 0.56, green: 0.40, blue: 0.18)
            ]
        case .light:
            colors = [
                Color(red: 0.14, green: 0.48, blue: 0.85),
                Color(red: 0.06, green: 0.65, blue: 0.62),
                Color(red: 0.98, green: 0.68, blue: 0.22)
            ]
        @unknown default:
            colors = [accent, sky]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func softBubbleGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.18),
                tint.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func color(for decision: OutdoorDecision) -> Color {
        switch decision {
        case .good: return success
        case .moderate: return accent
        case .risky: return warning
        case .avoid: return danger
        }
    }

    static func color(for severity: RiskLevel) -> Color {
        switch severity {
        case .low: return teal
        case .medium: return warning
        case .high, .extreme: return danger
        }
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)

            WeatherBackgroundSymbol(
                name: "cloud.sun.fill",
                size: 160,
                opacity: colorScheme == .dark ? 0.08 : 0.14,
                alignment: .topTrailing,
                xOffset: 40,
                yOffset: -40
            )

            WeatherBackgroundSymbol(
                name: "cloud.rain.fill",
                size: 110,
                opacity: colorScheme == .dark ? 0.06 : 0.10,
                alignment: .bottomLeading,
                xOffset: -30,
                yOffset: 20
            )
        }
        .ignoresSafeArea()
    }
}

private struct WeatherBackgroundSymbol: View {
    private enum Constant {
        static let minDuration: Double = 5
        static let maxDuration: Double = 8
    }

    let name: String
    let size: CGFloat
    let opacity: Double
    let alignment: Alignment
    let xOffset: CGFloat
    let yOffset: CGFloat

    @State private var isAnimating = false

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(.white.opacity(opacity))
            .offset(x: xOffset, y: isAnimating ? yOffset - 10 : yOffset + 10)
            .animation(
                .easeInOut(duration: animationDuration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)
    }

    private var animationDuration: Double {
        Double.random(in: Constant.minDuration...Constant.maxDuration)
    }
}
