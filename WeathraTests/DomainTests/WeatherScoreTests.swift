import Testing
@testable import Weathra

struct WeatherScoreTests {
    @Test func rawValueClampsToValidRange() {
        #expect(WeatherScore(rawValue: -20).rawValue == 0)
        #expect(WeatherScore(rawValue: 120).rawValue == 100)
    }

    @Test func displayValueUsesTenPointScale() {
        let score = WeatherScore(rawValue: 85)

        #expect(score.displayValue == 8.5)
    }

    @Test func defaultLabelFollowsScoreBands() {
        L10n.configure(language: .english)

        #expect(WeatherScore(rawValue: 90).label == L10n.text("decision_good"))
        #expect(WeatherScore(rawValue: 70).label == L10n.text("decision_moderate"))
        #expect(WeatherScore(rawValue: 50).label == L10n.text("decision_risky"))
        #expect(WeatherScore(rawValue: 20).label == L10n.text("decision_avoid"))
    }

    @Test func customLabelIsPreserved() {
        let score = WeatherScore(rawValue: 75, label: "Custom")

        #expect(score.label == "Custom")
    }
}
