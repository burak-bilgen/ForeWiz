import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.10, green: 0.43, blue: 0.82)
    static let sky = Color(red: 0.32, green: 0.67, blue: 0.93)
    static let teal = Color(red: 0.04, green: 0.62, blue: 0.58)
    static let sunshine = Color(red: 0.95, green: 0.64, blue: 0.18)
    static let rain = Color(red: 0.25, green: 0.50, blue: 0.78)
    static let success = Color(red: 0.07, green: 0.55, blue: 0.38)
    static let warning = Color(red: 0.86, green: 0.48, blue: 0.14)
    static let danger = Color(red: 0.82, green: 0.20, blue: 0.26)
    static let ink = Color.primary
    static let secondaryText = Color.secondary
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let cardRadius: CGFloat = 22
    static let compactRadius: CGFloat = 14
    static let iconBubbleRadius: CGFloat = 10

    static func accent(for palette: AppAccentPalette) -> Color {
        switch palette {
        case .sky:
            accent
        case .mint:
            teal
        case .ember:
            warning
        }
    }

    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let colors: [Color]

        switch colorScheme {
        case .dark:
            colors = [
                Color(red: 0.04, green: 0.07, blue: 0.10),
                Color(red: 0.06, green: 0.12, blue: 0.16),
                Color(red: 0.12, green: 0.12, blue: 0.13)
            ]
        case .light:
            colors = [
                Color(red: 0.90, green: 0.96, blue: 0.98),
                Color(red: 0.98, green: 0.99, blue: 0.97),
                Color(red: 0.96, green: 0.93, blue: 0.87)
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
                Color(red: 0.08, green: 0.22, blue: 0.42),
                Color(red: 0.05, green: 0.43, blue: 0.48),
                Color(red: 0.54, green: 0.37, blue: 0.16)
            ]
        case .light:
            colors = [
                Color(red: 0.11, green: 0.44, blue: 0.80),
                Color(red: 0.04, green: 0.62, blue: 0.58),
                Color(red: 0.95, green: 0.64, blue: 0.18)
            ]
        @unknown default:
            colors = [accent, sky]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func softBubbleGradient(tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.22),
                tint.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func color(for decision: OutdoorDecision) -> Color {
        switch decision {
        case .good:
            success
        case .moderate:
            accent
        case .risky:
            warning
        case .avoid:
            danger
        }
    }

    static func color(for severity: RiskLevel) -> Color {
        switch severity {
        case .low:
            teal
        case .medium:
            warning
        case .high, .extreme:
            danger
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
                size: 170,
                opacity: colorScheme == .dark ? 0.10 : 0.18,
                alignment: .topTrailing,
                xOffset: 34,
                yOffset: -34
            )

            WeatherBackgroundSymbol(
                name: "cloud.rain.fill",
                size: 120,
                opacity: colorScheme == .dark ? 0.08 : 0.12,
                alignment: .bottomLeading,
                xOffset: -28,
                yOffset: 18
            )
        }
        .ignoresSafeArea()
    }
}

private struct WeatherBackgroundSymbol: View {
    let name: String
    let size: CGFloat
    let opacity: Double
    let alignment: Alignment
    let xOffset: CGFloat
    let yOffset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Image(systemName: name)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white.opacity(opacity))
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: alignment)
                .offset(x: xOffset, y: yOffset)
                .accessibilityHidden(true)
        }
    }
}
