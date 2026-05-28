import Foundation
import WizPathKit

/// Bridges WizPathKit's localization to the main app's L10n system.
/// Without this provider, WizPathKit falls back to DefaultL10nProvider which
/// returns the key string as-is (e.g. "wizpath_route_planner" instead of "Route Planner").
struct ForeWizL10nProvider: WizPathL10nProvider {
    func text(_ key: String) -> String {
        L10n.text(key)
    }

    func formatted(_ key: String, _ arguments: [CVarArg]) -> String {
        let format = L10n.text(key)
        let safeFormat = L10n.sanitizedFormat(format)
        return String(format: safeFormat, locale: L10n.locale, arguments: arguments)
    }
}
