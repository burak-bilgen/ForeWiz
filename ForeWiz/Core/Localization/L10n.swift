import Foundation

enum L10n {
    private enum Constant {
        static let languageOverrideKey = "forewiz.languageOverride.v1"
        static let appGroupSuiteName = "group.forewiz"
        static let fallbackLanguageCode = "en"
        static let supportedLanguageCodes = Set(["en", "tr"])
    }

    static func configure(language: AppLanguage, userDefaults: UserDefaults = .standard) {
        let sharedUserDefaults = UserDefaults(suiteName: Constant.appGroupSuiteName)

        if let localeIdentifier = language.localeIdentifier {
            userDefaults.set(localeIdentifier, forKey: Constant.languageOverrideKey)
            sharedUserDefaults?.set(localeIdentifier, forKey: Constant.languageOverrideKey)
        } else {
            userDefaults.removeObject(forKey: Constant.languageOverrideKey)
            sharedUserDefaults?.removeObject(forKey: Constant.languageOverrideKey)
        }

        clearBundleCache()
    }

    static func text(_ key: String) -> String {
        text(key, languageCode: currentLanguageCode)
    }

    static func text(_ key: String, lang languageCode: String) -> String {
        text(key, languageCode: normalizedLanguageCode(languageCode) ?? Constant.fallbackLanguageCode)
    }

    static func formatted(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }

    static var locale: Locale {
        Locale(identifier: currentLanguageCode)
    }

    static var currentLanguageCode: String {
        if let override = UserDefaults.standard.string(forKey: Constant.languageOverrideKey),
           let languageCode = normalizedLanguageCode(override) {
            return languageCode
        }

        return preferredSupportedLanguageCode
    }

    private static var preferredSupportedLanguageCode: String {
        for identifier in Locale.preferredLanguages {
            if let languageCode = normalizedLanguageCode(identifier) {
                return languageCode
            }
        }

        return Constant.fallbackLanguageCode
    }

    private static func text(_ key: String, languageCode: String) -> String {
        let localizedBundle = bundle(for: languageCode)
        let localized = localizedBundle.localizedString(forKey: key, value: nil, table: nil)

        if localized != key || languageCode == Constant.fallbackLanguageCode {
            return localized
        }

        return bundle(for: Constant.fallbackLanguageCode).localizedString(forKey: key, value: key, table: nil)
    }

    private static var bundleCache: [String: Bundle] = [:]

    private static func bundle(for languageCode: String) -> Bundle {
        if let cached = bundleCache[languageCode] {
            return cached
        }
        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        bundleCache[languageCode] = bundle
        return bundle
    }

    static func clearBundleCache() {
        bundleCache.removeAll()
    }

    private static func normalizedLanguageCode(_ identifier: String) -> String? {
        let normalized = identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first
            .map(String.init)?
            .lowercased()

        guard let normalized, Constant.supportedLanguageCodes.contains(normalized) else {
            return nil
        }

        return normalized
    }
}
