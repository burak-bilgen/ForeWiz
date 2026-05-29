import Foundation

/// Shared date formatters that respect the user's locale and regional preferences.
enum SharedFormatters {
    /// Short time style — respects user's 12h/24h preference (e.g. "3:45 PM" or "15:45").
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    /// Short date + short time — e.g. "15 May 3:45 PM"
    static let dateAndTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()
}
