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

        #expect(cold.lowercased().contains("üşü"))
        #expect(normal.lowercased().contains("normal"))
        #expect(hot.lowercased().contains("sıca"))
    }

    @Test func homeLabelsNoLazyLowercase() {
        let homeLabels = [
            "home_metric_feels", "home_metric_high", "home_metric_low",
            "home_metric_humidity", "home_score_out_of_10",
            "home_score_out_of_100", "home_assistant_badge",
            "home_hourly_label", "home_forecast_label",
            "wizpath_plan_journey", "wizpath_tap_destination",
            "home_attribution_powered", "home_attribution_updated",
            "home_loading_text", "home_outfit_card_title",
        ]
        for key in homeLabels {
            let tr = L10n.text(key, lang: "tr")
            let en = L10n.text(key, lang: "en")
            #expect(
                tr != tr.lowercased() || tr == en,
                "Lazy lowercase TR for \(key): '\(tr)'"
            )
            #expect(!tr.isEmpty, "Empty TR for \(key)")
        }
    }

    @Test func weekdayNamesAreNotEmptyAndNotLazy() {
        let days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        for day in days {
            let tr = L10n.text(day, lang: "tr")
            #expect(!tr.isEmpty, "Empty weekday name for \(day)")
            #expect(tr != day.lowercased(), "Weekday \(day) has lazy TR: '\(tr)'")
        }
    }

    @Test func timeFormatHourIsNotPlaceholder() {
        let tr = L10n.text("time_format_hour", lang: "tr")
        let en = L10n.text("time_format_hour", lang: "en")
        #expect(tr != "time format hour", "time_format_hour still has placeholder TR")
        #expect(en != "Time Format Hour", "time_format_hour still has placeholder EN")
    }

    @Test func turkishHasProperCharacters() {
        let keys = [
            "home_assistant_summary_good_format",
            "home_assistant_summary_moderate_format",
            "home_assistant_summary_risky_format",
            "home_assistant_summary_moderate_no_window",
            "use_this_as_a_natural",
            "avoid_long_exposed_outdoor_time",
            "decision_avoid_message",
        ]
        let badPatterns = ["disarida", "disari", "yürüyüs", "isler", "kisa", "kosullari", "degil", "batimini", "isareti", "aralik"]
        for key in keys {
            let tr = L10n.text(key, lang: "tr")
            for pattern in badPatterns {
                #expect(
                    !tr.contains(pattern),
                    "Missing Turkish chars in \(key): contains '\(pattern)'"
                )
            }
        }
    }

    @Test func scoreRingLabelsFit() {
        let outOf10 = L10n.text("home_score_out_of_10", lang: "tr")
        let outOf100 = L10n.text("home_score_out_of_100", lang: "tr")
        #expect(outOf10.count <= 4, "home_score_out_of_10 too long for ring: '\(outOf10)'")
        #expect(outOf100.count <= 5, "home_score_out_of_100 too long for ring: '\(outOf100)'")
    }

    @Test func wizpathHUDLabelsFit() {
        let plan = L10n.text("wizpath_plan_journey", lang: "tr")
        let tap = L10n.text("wizpath_tap_destination", lang: "tr")
        #expect(plan.count <= 20, "wizpath_plan_journey too long: '\(plan)'")
        #expect(tap.count <= 20, "wizpath_tap_destination too long: '\(tap)'")
    }
}
