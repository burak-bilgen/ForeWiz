import Testing
@testable import ForeWiz

struct LocalizationTests {
    @Test func turkishLocalizationReturnsCorrectValue() {
        let result = L10n.text("settings_title", lang: "tr")
        #expect(result == "Ayarlar")
    }

    @Test func englishLocalizationReturnsCorrectValue() {
        let result = L10n.text("settings_title", lang: "en")
        #expect(result == "Settings")
    }

    @Test func languageSwitchingWorks() {
        let turkish = L10n.text("home_title", lang: "tr")
        let english = L10n.text("home_title", lang: "en")

        #expect(turkish != english)
    }

    @Test func appLanguageLocaleReturnsCorrectValue() {
        let turkish = AppLanguage.turkish.localeIdentifier
        #expect(turkish == "tr")

        let english = AppLanguage.english.localeIdentifier
        #expect(english == "en")
    }

    @Test func temperatureSensitivityLocalizedText() {
        let cold = L10n.text("sensitivity_cold", lang: "tr")
        let normal = L10n.text("sensitivity_normal", lang: "tr")
        let hot = L10n.text("sensitivity_hot", lang: "tr")

        #expect(cold.lowercased().contains("soğu"))
        #expect(normal.lowercased().contains("normal"))
        #expect(hot.lowercased().contains("sıca"))
    }
}
