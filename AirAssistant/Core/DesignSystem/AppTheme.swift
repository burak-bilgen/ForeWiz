import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.08, green: 0.45, blue: 0.76)
    static let success = Color(red: 0.13, green: 0.55, blue: 0.34)
    static let warning = Color(red: 0.78, green: 0.46, blue: 0.10)
    static let danger = Color(red: 0.78, green: 0.18, blue: 0.20)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.90, green: 0.96, blue: 0.99),
                Color(red: 0.97, green: 0.95, blue: 0.90),
                Color(red: 0.89, green: 0.94, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
