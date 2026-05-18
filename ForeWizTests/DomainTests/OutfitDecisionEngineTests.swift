import Foundation
import Testing
@testable import ForeWiz

struct OutfitDecisionEngineTests {
    private let engine = DefaultOutfitDecisionEngine()

    // MARK: - Base item tests (existing)

    @Test func warmWeatherOutfitIsLight() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 30 },
            apparentTemperature: { _ in 32 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        let tshirtKey = L10n.text("outfit_light_tshirt")
        #expect(outfit.items.contains(tshirtKey))
    }

    @Test func coldWeatherOutfitIncludesWarmLayers() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 1, day: 15, hour: 10)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 5 },
            apparentTemperature: { _ in 3 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        let coatKey = L10n.text("outfit_winter_coat")
        #expect(outfit.items.contains(coatKey))
    }

    @Test func moderateTemperatureIncludesLightJacket() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 20 },
            apparentTemperature: { _ in 20 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        let lightJacketKey = L10n.text("outfit_light_jacket")
        #expect(outfit.items.contains(lightJacketKey))
    }

    // MARK: - Rain risk tests

    @Test func rainRiskIncludesUmbrella() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 20 },
            apparentTemperature: { _ in 20 }
        )

        let risks = [WeatherRisk(type: .rain, severity: .high, title: "Rain", message: "Heavy rain")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.accessories.contains(L10n.text("outfit_umbrella")))
        #expect(outfit.warning == L10n.text("outfit_warning_rain"))
    }

    @Test func rainRiskAdviceMentionsRain() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 20 },
            apparentTemperature: { _ in 20 }
        )

        let risks = [WeatherRisk(type: .rain, severity: .high, title: "Rain", message: "Heavy rain")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        if let advice = outfit.detailedAdvice {
            #expect(advice.contains(L10n.text("outfit_advice_rain")))
        }
    }

    // MARK: - Heat / UV tests

    @Test func heatAndUVRiskIncludesSunglassesAndHat() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 35 },
            apparentTemperature: { _ in 37 }
        )

        let risks = [WeatherRisk(type: .heat, severity: .high, title: "Heat", message: "Extreme heat")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.accessories.contains(L10n.text("outfit_sunglasses")))
        #expect(outfit.accessories.contains(L10n.text("outfit_hat")))
    }

    @Test func extremeHeatGeneratesSunProtectionAdvice() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 10, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 38 },
            apparentTemperature: { _ in 40 }
        )

        let risks = [WeatherRisk(type: .heat, severity: .high, title: "Heat", message: "Extreme heat")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        if let advice = outfit.detailedAdvice {
            #expect(advice.contains(L10n.text("outfit_advice_sun_protection")))
        }
    }

    // MARK: - Wind risk tests

    @Test func windRiskAddsWindbreaker() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 18 },
            apparentTemperature: { _ in 16 }
        )

        let risks = [WeatherRisk(type: .wind, severity: .high, title: "Wind", message: "Strong wind")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.items.contains(L10n.text("outfit_windbreaker")))
    }

    @Test func windRiskAdviceMentionsWind() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 6, hour: 9)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 18 },
            apparentTemperature: { _ in 16 }
        )

        let risks = [WeatherRisk(type: .wind, severity: .high, title: "Wind", message: "Strong wind")]
        let input = makeInput(snapshot: snapshot, calendar: calendar, risks: risks)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        if let advice = outfit.detailedAdvice {
            #expect(advice.contains(L10n.text("outfit_advice_wind")))
        }
    }

    // MARK: - Temperature band advice tests

    @Test func freezingTemperatureGeneratesAdvice() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 1, day: 5, hour: 10)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 0 },
            apparentTemperature: { _ in -2 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        #expect(outfit.items.contains(L10n.text("outfit_winter_coat")))
    }

    @Test func hotAndHumidDayGeneratesAdvice() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 7, day: 15, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 32 },
            apparentTemperature: { _ in 34 },
            humidity: { _ in 0.75 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
    }

    // MARK: - Evening cooling warning test

    @Test func eveningCoolingAddsWarning() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 4, day: 10, hour: 20)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { hour in
                if hour >= 6, hour <= 10 { return 22 }
                if hour >= 12, hour <= 16 { return 24 }
                return 18
            },
            apparentTemperature: { hour in
                if hour >= 6, hour <= 10 { return 22 }
                if hour >= 12, hour <= 16 { return 24 }
                return 17
            }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.warning == L10n.text("outfit_warning_evening"))
    }

    // MARK: - detailedAdvice is always generated

    @Test func allOutfitsHaveDetailedAdvice() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 6, day: 15, hour: 12)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 22 },
            apparentTemperature: { _ in 22 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        #expect(outfit.detailedAdvice?.isEmpty == false)
    }

    // MARK: - Temperature swing (layer advice)

    @Test func largeTemperatureSwingGeneratesLayerAdvice() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 4, day: 15, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { hour in
                // Morning (6-10): cool 14°C, Afternoon (12-16): warm 26°C → 12°C swing
                if hour >= 6, hour <= 10 { return 14 }
                if hour >= 12, hour <= 16 { return 26 }
                return 18
            },
            apparentTemperature: { hour in
                if hour >= 6, hour <= 10 { return 14 }
                if hour >= 12, hour <= 16 { return 26 }
                return 18
            }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.detailedAdvice != nil)
        if let advice = outfit.detailedAdvice {
            #expect(advice.contains(L10n.text("outfit_advice_layer_swing")))
        }
    }

    // MARK: - Mild temperature title

    @Test func mildDayOutfitHasCorrectTitle() {
        let calendar = WeatherTestFixtures.calendar
        let now = WeatherTestFixtures.date(month: 5, day: 15, hour: 14)
        let snapshot = WeatherTestFixtures.snapshot(
            now: now,
            temperature: { _ in 22 },
            apparentTemperature: { _ in 22 }
        )

        let input = makeInput(snapshot: snapshot, calendar: calendar)
        let outfit = engine.recommendOutfit(input: input)

        #expect(outfit.title == L10n.text("outfit_title_mild"))
    }

    // MARK: - Helpers

    private func makeInput(
        snapshot: WeatherSnapshot,
        calendar: Calendar,
        risks: [WeatherRisk] = [],
        avoidWindows: [AvoidWindowRecommendation] = []
    ) -> OutfitRecommendationInput {
        OutfitRecommendationInput(
            current: snapshot.current,
            hourly: snapshot.hourly,
            profile: WeatherTestFixtures.profile(),
            risks: risks,
            avoidWindows: avoidWindows,
            calendar: calendar
        )
    }
}
