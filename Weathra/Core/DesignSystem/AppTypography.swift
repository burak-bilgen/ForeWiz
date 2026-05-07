import SwiftUI

/// Typography tokens. Values are dynamic-type aware (text styles) so they scale with user
/// preferences. Use `.numeric` styles for digits to keep them compact and aligned.
enum AppTypography {
    // Display / headlines
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title, design: .rounded, weight: .bold)
    static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
    static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)

    // Body text
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded, weight: .regular)
    static let bodyEmphasized = Font.system(.body, design: .rounded, weight: .semibold)
    static let callout = Font.system(.callout, design: .rounded, weight: .regular)
    static let footnote = Font.system(.footnote, design: .rounded, weight: .regular)
    static let caption = Font.system(.caption, design: .rounded, weight: .regular)
    static let caption2 = Font.system(.caption2, design: .rounded, weight: .medium)

    // Numeric / data display (rounded with consistent digit widths)
    /// For very large hero numbers like the headline temperature.
    static let heroNumber = Font.system(size: 64, weight: .semibold, design: .rounded)
    /// For prominent numbers (scores, secondary readings).
    static let displayNumber = Font.system(size: 36, weight: .semibold, design: .rounded)
    /// Compact numeric label (uses monospaced digits for stable alignment).
    static let metricNumber = Font.system(.title3, design: .rounded, weight: .semibold)
}
