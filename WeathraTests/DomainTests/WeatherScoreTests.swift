import Testing
@testable import Weathra

struct WeatherScoreTests {
    @Test func scoreCalculationForGoodConditions() {
        let score = WeatherScore.calculate(
            temperature: 22,
            humidity: 0.45,
            windSpeedKph: 10,
            precipitationChance: 0.1,
            uvIndex: 3,
            isDaylight: true
        )

        #expect(score >= 80)
    }

    @Test func scoreCalculationForBadConditions() {
        let score = WeatherScore.calculate(
            temperature: 38,
            humidity: 0.85,
            windSpeedKph: 45,
            precipitationChance: 0.8,
            uvIndex: 11,
            isDaylight: true
        )

        #expect(score < 50)
    }

    @Test func scoreCalculationForExtremeHeat() {
        let score = WeatherScore.calculate(
            temperature: 42,
            humidity: 0.3,
            windSpeedKph: 5,
            precipitationChance: 0.0,
            uvIndex: 10,
            isDaylight: true
        )

        #expect(score < 40)
    }

    @Test func scoreCalculationForExtremeCold() {
        let score = WeatherScore.calculate(
            temperature: -5,
            humidity: 0.7,
            windSpeedKph: 30,
            precipitationChance: 0.3,
            uvIndex: 1,
            isDaylight: true
        )

        #expect(score < 30)
    }

    @Test func scoreCalculationForPerfectDay() {
        let score = WeatherScore.calculate(
            temperature: 24,
            humidity: 0.5,
            windSpeedKph: 8,
            precipitationChance: 0.0,
            uvIndex: 4,
            isDaylight: true
        )

        #expect(score >= 90)
    }

    @Test func displayValueRoundsToInteger() {
        let score = WeatherScore(rawValue: 85.7)
        #expect(score.displayValue == 86)
    }

    @Test func scoreClampingWorksForNegativeValues() {
        let score = WeatherScore.calculate(
            temperature: 50,
            humidity: 0.9,
            windSpeedKph: 100,
            precipitationChance: 1.0,
            uvIndex: 15,
            isDaylight: true
        )

        #expect(score.rawValue >= 0)
        #expect(score.rawValue <= 100)
    }
}