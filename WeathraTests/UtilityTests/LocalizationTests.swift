import Testing
@testable import Weathra

struct LocalizationTests {
    @Test func turkishLocalizationReturnsCorrectValue() {
        L10n.configure(language: .turkish)

        let result = L10n.text("settings_title")
        #expect(result == "Ayarlar")
    }

    @Test func englishLocalizationReturnsCorrectValue() {
        L10n.configure(language: .english)

        let result = L10n.text("settings_title")
        #expect(result == "Settings")
    }

    @Test func languageSwitchingWorks() {
        L10n.configure(language: .turkish)
        let turkish = L10n.text("home_title")

        L10n.configure(language: .english)
        let english = L10n.text("home_title")

        #expect(turkish != english)
    }

    @Test func appLanguageLocaleReturnsCorrectValue() {
        let turkish = AppLanguage.turkish.locale
        #expect(turkish.languageCode == "tr")

        let english = AppLanguage.english.locale
        #expect(english.languageCode == "en")
    }

    @Test func temperatureSensitivityLocalizedText() {
        L10n.configure(language: .turkish)

        let cold = TemperatureSensitivity.getsColdEasily.localizedTitle
        let normal = TemperatureSensitivity.normal.localizedTitle
        let hot = TemperatureSensitivity.getsHotEasily.localizedTitle

        #expect(cold.contains("soğuk"))
        #expect(normal.contains("normal"))
        #expect(hot.contains("sıcak"))
    }
}