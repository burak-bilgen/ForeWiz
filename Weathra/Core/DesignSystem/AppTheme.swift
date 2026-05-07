import SwiftUI
import UIKit

/// Central design tokens for Weathra.
///
/// The colour palette favours system semantic colours (which adapt to light/dark mode automatically)
/// for surfaces and text, and a small set of carefully tuned brand colours for accents and weather
/// states. Gradients are derived from current conditions instead of a single rainbow stack.
enum AppTheme {

    // MARK: - Brand & accent palette

    /// Primary brand accent (used for tints, links, selected states).
    static let accent = Color(red: 0.20, green: 0.52, blue: 0.96)

    /// A softer secondary accent for highlights.
    static let accentSoft = Color(red: 0.46, green: 0.74, blue: 0.98)

    static let sky = Color(red: 0.42, green: 0.74, blue: 0.96)
    static let teal = Color(red: 0.18, green: 0.71, blue: 0.66)
    static let sunshine = Color(red: 0.99, green: 0.74, blue: 0.28)
    static let coral = Color(red: 0.98, green: 0.49, blue: 0.46)
    static let purple = Color(red: 0.55, green: 0.40, blue: 0.92)
    static let pink = Color(red: 0.96, green: 0.53, blue: 0.72)
    static let rain = Color(red: 0.36, green: 0.56, blue: 0.82)

    // MARK: - Status / decision colours

    static let success = Color(red: 0.20, green: 0.66, blue: 0.46)
    static let warning = Color(red: 0.93, green: 0.60, blue: 0.18)
    static let danger = Color(red: 0.88, green: 0.28, blue: 0.32)

    // MARK: - Semantic surfaces & text (auto adapt to light/dark)

    /// Primary text colour.
    static let ink = Color(uiColor: .label)
    /// Secondary text colour.
    static let secondaryText = Color(uiColor: .secondaryLabel)
    /// Tertiary text colour.
    static let tertiaryText = Color(uiColor: .tertiaryLabel)

    /// Page background (use as the root container behind cards).
    static let background = Color(uiColor: .systemBackground)
    /// Grouped page background (for forms / lists).
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    /// Surface for cards on a plain background.
    static let surface = Color(uiColor: .secondarySystemBackground)
    /// Elevated card surface.
    static let elevatedSurface = Color(uiColor: .tertiarySystemBackground)

    /// Hairline separator colour.
    static let separator = Color(uiColor: .separator)

    // MARK: - Geometry tokens

    static let cardRadius: CGFloat = 22
    static let compactRadius: CGFloat = 14
    static let iconBubbleRadius: CGFloat = 12
    static let pillRadius: CGFloat = 18

    // MARK: - Animations

    /// Spring used for view-state transitions.
    static let springSmooth: Animation = .spring(response: 0.45, dampingFraction: 0.85)
    /// Snappier spring for interactions.
    static let springSnappy: Animation = .spring(response: 0.32, dampingFraction: 0.78)
    /// Standard ease for fades/cross-fades.
    static let smooth: Animation = .easeInOut(duration: 0.28)
    /// Fast ease for taps.
    static let quick: Animation = .easeOut(duration: 0.18)

    // MARK: - Palette mapping

    static func accent(for palette: AppAccentPalette) -> Color {
        switch palette {
        case .sky: accent
        case .mint: teal
        case .ember: sunshine
        }
    }

    static func color(for decision: OutdoorDecision) -> Color {
        switch decision {
        case .good: success
        case .moderate: accent
        case .risky: warning
        case .avoid: danger
        }
    }

    static func color(for severity: RiskLevel) -> Color {
        switch severity {
        case .low: accent
        case .medium: warning
        case .high, .extreme: danger
        }
    }

    // MARK: - Gradients

    /// Subtle ambient page gradient. Keep low contrast so text stays readable
    /// regardless of mode.
    static func ambientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.10),
                    Color(red: 0.06, green: 0.10, blue: 0.16),
                    Color(red: 0.04, green: 0.06, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.98, blue: 1.00),
                    Color(red: 0.93, green: 0.96, blue: 1.00),
                    Color(red: 0.98, green: 0.96, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    /// Hero gradient that shifts with the current decision colour. Used behind the headline card.
    static func heroGradient(for decision: OutdoorDecision, colorScheme: ColorScheme) -> LinearGradient {
        let base = color(for: decision)
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    base.opacity(0.55),
                    base.opacity(0.30).blended(with: .black, fraction: 0.25),
                    Color(red: 0.06, green: 0.10, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    base.opacity(0.95),
                    base.opacity(0.85).blended(with: .white, fraction: 0.10),
                    base.opacity(0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Soft tinted bubble gradient used behind icons.
    static func softBubble(_ tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.22), tint.opacity(0.06)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color helpers

private extension Color {
    /// Linearly blends this colour towards another in sRGB.
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

// MARK: - Backwards-compatible aliases (will be removed after redesign sweep)

extension AppTheme {
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        ambientBackground(for: colorScheme)
    }

    static func weatherGradient(for colorScheme: ColorScheme) -> LinearGradient {
        heroGradient(for: .moderate, colorScheme: colorScheme)
    }

    static func softBubbleGradient(tint: Color) -> LinearGradient {
        softBubble(tint)
    }

    static func glassFill(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: Color.white.opacity(0.06)
        default:    Color.white.opacity(0.55)
        }
    }

    static func glassStroke(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark: Color.white.opacity(0.14)
        default:    Color.primary.opacity(0.06)
        }
    }

    static func glassAccentShadow(for colorScheme: ColorScheme, isEnabled: Bool) -> Color {
        guard isEnabled else { return .clear }
        return colorScheme == .dark ? accent.opacity(0.16) : accent.opacity(0.08)
    }

    static func glassDepthShadow(for colorScheme: ColorScheme, isEnabled: Bool) -> Color {
        guard isEnabled else { return .clear }
        return colorScheme == .dark ? .black.opacity(0.18) : .black.opacity(0.04)
    }

    static var springAnimation: Animation { springSmooth }
    static var smoothAnimation: Animation { smooth }
    static var quickAnimation: Animation { quick }
}

// MARK: - App background

/// Calm ambient background. No animated symbols (those felt dated).
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.ambientBackground(for: colorScheme)
            .ignoresSafeArea()
    }
}
