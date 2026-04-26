import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.05, green: 0.39, blue: 0.72)
    static let teal = Color(red: 0.06, green: 0.57, blue: 0.54)
    static let success = Color(red: 0.11, green: 0.52, blue: 0.33)
    static let warning = Color(red: 0.78, green: 0.48, blue: 0.12)
    static let danger = Color(red: 0.78, green: 0.18, blue: 0.20)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let surface = Color.white.opacity(0.72)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.86, green: 0.94, blue: 0.99),
                Color(red: 0.96, green: 0.98, blue: 0.94),
                Color(red: 0.99, green: 0.92, blue: 0.82)
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
