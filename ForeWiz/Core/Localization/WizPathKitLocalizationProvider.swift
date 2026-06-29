import Foundation
import WizPathKit

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
