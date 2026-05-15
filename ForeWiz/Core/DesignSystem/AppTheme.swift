import SwiftUI
import UIKit

/// 🎨 ForeWiz Liquid Glass Design System
///
/// A premium, weather-aware color palette built around Apple's Liquid Glass aesthetic.
/// Features vibrant, saturated accent colors with deep glass morphism support.
enum AppTheme {

    // MARK: - Liquid Glass Core

    /// Primary dynamic accent - shifts with context, always vibrant.
    static let liquidAccent = Color(red: 0.25, green: 0.60, blue: 1.0)

    /// Secondary accent for highlights and badges.
    static let liquidAccentSoft = Color(red: 0.45, green: 0.75, blue: 1.0)

    /// Deep base for glass surfaces.
    static let liquidBase = Color(red: 0.06, green: 0.08, blue: 0.14)

    /// Surface overlay for glass cards.
    static let liquidSurface = Color(red: 0.10, green: 0.12, blue: 0.20)

    /// Glow effect color for active states.
    static let liquidGlow = Color(red: 0.20, green: 0.50, blue: 1.0).opacity(0.3)

    // MARK: - Weather-Inspired Accents

    /// Clear sky - bright, cheerful blue.
    static let sky = Color(red: 0.35, green: 0.68, blue: 1.0)

    /// Deep ocean - for rainy conditions.
    static let ocean = Color(red: 0.18, green: 0.40, blue: 0.75)

    /// Teal - for moderate, balanced weather.
    static let teal = Color(red: 0.15, green: 0.75, blue: 0.68)

    /// Golden sunshine - warm, bright.
    static let sunshine = Color(red: 1.0, green: 0.75, blue: 0.25)

    /// Warm ember - for hot conditions.
    static let ember = Color(red: 1.0, green: 0.55, blue: 0.20)

    /// Vibrant coral - for warnings/alerts.
    static let coral = Color(red: 1.0, green: 0.40, blue: 0.40)

    /// Royal purple - for storms/dramatic weather.
    static let royalPurple = Color(red: 0.55, green: 0.35, blue: 0.95)

    /// Soft pink - for dawn/dusk transitions.
    static let dawnPink = Color(red: 0.95, green: 0.50, blue: 0.70)

    /// Icy blue - for cold/snow conditions.
    static let ice = Color(red: 0.70, green: 0.85, blue: 1.0)

    /// Storm gray - for fog/overcast.
    static let stormGray = Color(red: 0.45, green: 0.50, blue: 0.60)

    // MARK: - Status / Decision Colors

    /// Optimal outdoor conditions - rich emerald.
    static let success = Color(red: 0.18, green: 0.70, blue: 0.48)

    /// Moderate conditions - warm amber.
    static let warning = Color(red: 0.95, green: 0.62, blue: 0.18)

    /// Avoid/postpone - vibrant coral.
    static let danger = Color(red: 0.92, green: 0.28, blue: 0.32)

    // MARK: - Semantic Tokens

    static let ink = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let tertiaryText = Color(uiColor: .tertiaryLabel)

    static let background = Color(uiColor: .systemBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let elevatedSurface = Color(uiColor: .tertiarySystemBackground)

    static let separator = Color(uiColor: .separator)

    // MARK: - Geometry Tokens

    static let cardRadius: CGFloat = 22
    static let compactRadius: CGFloat = 14
    static let pillRadius: CGFloat = 18
    static let glassRadius: CGFloat = 20

    // MARK: - Animation Tokens

    static let springSmooth: Animation = .spring(response: 0.5, dampingFraction: 0.85)
    static let springSnappy: Animation = .spring(response: 0.32, dampingFraction: 0.78)
    static let smooth: Animation = .easeInOut(duration: 0.35)
    static let quick: Animation = .easeOut(duration: 0.18)
    static let springBouncy: Animation = .spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)

    // MARK: - Weather Decision → Color Mapping

    static func color(for decision: OutdoorDecision) -> Color {
        switch decision {
        case .good: success
        case .moderate: liquidAccent
        case .risky: warning
        case .avoid: danger
        }
    }

    static func color(for score: WeatherScore) -> Color {
        switch score.rawValue {
        case 80...100: success
        case 60..<80: liquidAccent
        case 40..<60: warning
        default: danger
        }
    }

    static func color(for severity: RiskLevel) -> Color {
        switch severity {
        case .low: liquidAccent
        case .medium: warning
        case .high, .extreme: danger
        }
    }

    static func toneColor(for tone: HomeAssistantTone) -> Color {
        switch tone {
        case .good: success
        case .caution: warning
        case .danger: danger
        case .info: liquidAccent
        }
    }

    // MARK: - Accent Palette

    static func accent(for palette: AppAccentPalette) -> Color {
        switch palette {
        case .sky: liquidAccent
        case .mint: teal
        case .ember: ember
        }
    }

    // MARK: - Liquid Glass Gradients

    /// Ambient page gradient with deep, rich tones.
    static func ambientGradient(for colorScheme: ColorScheme = .dark) -> LinearGradient {
        switch colorScheme {
        case .dark:
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.12),
                    Color(red: 0.06, green: 0.10, blue: 0.18),
                    Color(red: 0.04, green: 0.06, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.96, blue: 1.0),
                    Color(red: 0.90, green: 0.94, blue: 1.0),
                    Color(red: 0.96, green: 0.94, blue: 0.90)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Hero gradient that shifts with outdoor decision state.
    static func heroGradient(for decision: OutdoorDecision, colorScheme: ColorScheme = .dark) -> LinearGradient {
        let base = color(for: decision)
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    base.opacity(0.50),
                    base.opacity(0.25).blended(with: .black, fraction: 0.3),
                    Color(red: 0.04, green: 0.06, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    base.opacity(0.90),
                    base.opacity(0.75).blended(with: .white, fraction: 0.15),
                    base.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Soft tinted bubble for icon backgrounds.
    static func softBubble(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.25), tint.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Liquid glass sheen gradient for card overlays.
    static func glassSheen(_ accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.0),
                accent.opacity(0.10),
                .white.opacity(0.05),
                accent.opacity(0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Blending Helper

private extension Color {
    func blended(with other: Color, fraction: Double) -> Color {
        let lhs = UIColor(self)
        let rhs = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        lhs.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        rhs.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let f = CGFloat(max(0, min(1, fraction)))
        return Color(
            red: Double(r1 + (r2 - r1) * f),
            green: Double(g1 + (g2 - g1) * f),
            blue: Double(b1 + (b2 - b1) * f),
            opacity: Double(a1 + (a2 - a1) * f)
        )
    }
}

// MARK: - Color Extensions for Direct Use

@available(iOS 17.0, *)
extension Color {
    static let liquidAccent = AppTheme.liquidAccent
    static let success = AppTheme.success
    static let warning = AppTheme.warning
    static let danger = AppTheme.danger
    static let teal = AppTheme.teal
    static let ember = AppTheme.ember
    static let sky = AppTheme.sky
    static let royalPurple = AppTheme.royalPurple
    static let coral = AppTheme.coral
    static let ocean = AppTheme.ocean
    static let sunshine = AppTheme.sunshine
    static let dawnPink = AppTheme.dawnPink
    static let ice = AppTheme.ice
    static let stormGray = AppTheme.stormGray
    static let liquidBase = AppTheme.liquidBase
    static let liquidSurface = AppTheme.liquidSurface
    static let liquidAccentSoft = AppTheme.liquidAccentSoft
}

// MARK: - App Background


struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.ambientGradient(for: colorScheme)
            .ignoresSafeArea()
    }
}
