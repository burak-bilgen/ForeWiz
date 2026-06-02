import Foundation

enum L10n {
    private enum Constant {
        static let languageOverrideKey = AppKeys.UserDefaults.languageOverride
        static let appGroupSuiteName = AppKeys.appGroupSuiteName
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
        let format = text(key)
        let safeFormat = Self.sanitizedFormat(format)
        return String(format: safeFormat, locale: locale, arguments: arguments)
    }

    /// Escapes bare `%` in the format string that aren't part of valid
    /// format specifiers (`%@`, `%lld`, `%d`, `%f`, etc.), preventing
    /// `String(format:)` from crashing with EXC_BAD_ACCESS.
    ///
    /// For example, `"0%"` becomes `"0%%"` so the `%` renders as literal.
    /// `"%lld daha"` is left untouched since `%lld` is valid.
    /// `"%"` becomes `"%%"`.
    static func sanitizedFormat(_ format: String) -> String {
        let chars = Array(format)
        var result = ""
        var i = 0
        while i < chars.count {
            if chars[i] == "%" {
                if i + 1 < chars.count, chars[i + 1] == "%" {
                    result += "%%"
                    i += 2
                    continue
                }
                if i + 1 < chars.count, isValidFormatStart(chars[i + 1]) {
                    var j = i + 1
                    while j < chars.count {
                        let c = chars[j]
                        if c.isNumber || "-+#0.$ hlLzqtj'*".contains(c) {
                            j += 1
                        } else if c == "%" {
                            // Invalid: specifier with embedded % (like %% inside specifier)
                            result += "%%"
                            i = j + 1
                            break
                        } else {
                            // Conversion character or invalid
                            if "@dDiuUxXoOeEfFgGcCsSpPaA".contains(c) {
                                result += String(chars[i...j])
                                i = j + 1
                            } else {
                                result += "%%"
                                i = j
                            }
                            break
                        }
                    }
                    if j >= chars.count {
                        result += "%%"
                        i = chars.count
                    }
                } else {
                    result += "%%"
                    i += 1
                }
            } else {
                result.append(chars[i])
                i += 1
            }
        }
        return result
    }

    private static func isValidFormatStart(_ c: Character) -> Bool {
        c.isNumber || "-+#0.$ hlLzqtj'*@dDiuUxXoOeEfFgGcCsSpPaA%".contains(c)
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

    private static let lock = NSLock()
    private static var bundleCache: [String: Bundle] = [:]

    private static func bundle(for languageCode: String) -> Bundle {
        lock.lock()
        defer { lock.unlock() }
        
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
        lock.lock()
        defer { lock.unlock() }
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
