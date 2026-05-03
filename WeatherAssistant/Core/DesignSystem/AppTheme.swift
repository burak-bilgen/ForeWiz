import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.12, green: 0.45, blue: 0.93)
    static let sky = Color(red: 0.35, green: 0.70, blue: 0.98)
    static let teal = Color(red: 0.08, green: 0.68, blue: 0.70)
    static let sunshine = Color(red: 1.00, green: 0.72, blue: 0.22)
    static let rain = Color(red: 0.21, green: 0.56, blue: 0.84)
    static let success = Color(red: 0.08, green: 0.60, blue: 0.42)
    static let warning = Color(red: 0.92, green: 0.55, blue: 0.18)
    static let danger = Color(red: 0.88, green: 0.23, blue: 0.28)
    static let ink = Color.primary
    static let secondaryText = Color.secondary
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let cardRadius: CGFloat = 26
    static let compactRadius: CGFloat = 18
    static let iconBubbleRadius: CGFloat = 14

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
                Color(red: 0.03, green: 0.07, blue: 0.16),
                Color(red: 0.06, green: 0.13, blue: 0.24),
                Color(red: 0.15, green: 0.13, blue: 0.25)
            ]
        case .light:
            colors = [
                Color(red: 0.72, green: 0.90, blue: 1.00),
                Color(red: 0.91, green: 0.98, blue: 1.00),
                Color(red: 1.00, green: 0.94, blue: 0.80)
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
                Color(red: 0.11, green: 0.24, blue: 0.47),
                Color(red: 0.08, green: 0.43, blue: 0.60),
                Color(red: 0.42, green: 0.28, blue: 0.55)
            ]
        case .light:
            colors = [
                Color(red: 0.18, green: 0.54, blue: 0.96),
                Color(red: 0.43, green: 0.78, blue: 1.00),
                Color(red: 1.00, green: 0.78, blue: 0.33)
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
