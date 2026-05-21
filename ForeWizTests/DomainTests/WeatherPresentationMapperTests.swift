import Foundation
import Testing
@testable import ForeWiz

@Suite("WeatherPresentationMapper Tests")
struct WeatherPresentationMapperTests {
    
    private let mapper = WeatherPresentationMapper()
    
    @Test("conditionText maps thunderstorm")
    func conditionTextMapsThunderstorm() async throws {
        #expect(mapper.conditionText(for: "Thunderstorm") == L10n.text("weather_storm"))
        #expect(mapper.conditionText(for: "Thunder") == L10n.text("weather_storm"))
    }
    
    @Test("conditionText maps rain")
    func conditionTextMapsRain() async throws {
        #expect(mapper.conditionText(for: "Rain") == L10n.text("weather_rain"))
        #expect(mapper.conditionText(for: "Drizzle") == L10n.text("weather_rain"))
    }
    
    @Test("conditionText maps snow")
    func conditionTextMapsSnow() async throws {
        #expect(mapper.conditionText(for: "Snow") == L10n.text("weather_snow"))
        #expect(mapper.conditionText(for: "Sleet") == L10n.text("weather_snow"))
    }
    
    @Test("conditionText maps cloudy")
    func conditionTextMapsCloudy() async throws {
        #expect(mapper.conditionText(for: "Cloudy") == L10n.text("weather_cloudy"))
        #expect(mapper.conditionText(for: "MostlyCloudy") == L10n.text("weather_cloudy"))
    }
    
    @Test("conditionText maps fog")
    func conditionTextMapsFog() async throws {
        #expect(mapper.conditionText(for: "Fog") == L10n.text("weather_foggy"))
        #expect(mapper.conditionText(for: "Haze") == L10n.text("weather_foggy"))
    }
    
    @Test("conditionText maps clear")
    func conditionTextMapsClear() async throws {
        #expect(mapper.conditionText(for: "Clear") == L10n.text("weather_clear"))
        #expect(mapper.conditionText(for: "Sun") == L10n.text("weather_clear"))
    }
    
    @Test("conditionText returns default for unknown")
    func conditionTextReturnsDefaultForUnknown() async throws {
        #expect(mapper.conditionText(for: nil) == L10n.text("weather_current"))
        #expect(mapper.conditionText(for: "UnknownCondition") == L10n.text("weather_current"))
    }
    
    @Test("symbolName maps thunderstorm")
    func symbolNameMapsThunderstorm() async throws {
        #expect(mapper.symbolName(for: "Thunderstorm", isDaylight: true) == "cloud.bolt.rain.fill")
        #expect(mapper.symbolName(for: "Thunderstorm", isDaylight: false) == "cloud.bolt.rain.fill")
    }
    
    @Test("symbolName maps rain")
    func symbolNameMapsRain() async throws {
        #expect(mapper.symbolName(for: "Rain", isDaylight: true) == "cloud.rain.fill")
    }
    
    @Test("symbolName maps snow")
    func symbolNameMapsSnow() async throws {
        #expect(mapper.symbolName(for: "Snow", isDaylight: true) == "cloud.snow.fill")
    }
    
    @Test("symbolName maps cloudy with daylight")
    func symbolNameMapsCloudyWithDaylight() async throws {
        #expect(mapper.symbolName(for: "Cloudy", isDaylight: true) == "cloud.sun.fill")
        #expect(mapper.symbolName(for: "Cloudy", isDaylight: false) == "cloud.moon.fill")
    }
    
    @Test("symbolName maps fog")
    func symbolNameMapsFog() async throws {
        #expect(mapper.symbolName(for: "Fog", isDaylight: true) == "cloud.fog.fill")
    }
    
    @Test("symbolName maps clear with daylight")
    func symbolNameMapsClearWithDaylight() async throws {
        #expect(mapper.symbolName(for: "Clear", isDaylight: true) == "sun.max.fill")
        #expect(mapper.symbolName(for: "Clear", isDaylight: false) == "moon.stars.fill")
    }
    
    @Test("symbolName handles nil conditionCode")
    func symbolNameHandlesNilConditionCode() async throws {
        #expect(mapper.symbolName(for: nil, isDaylight: true) == "sun.max.fill")
        #expect(mapper.symbolName(for: nil, isDaylight: false) == "moon.stars.fill")
    }
    
    @Test("temperatureText metric formatting")
    func temperatureTextMetricFormatting() async throws {
        let text = mapper.temperatureText(25, unitSystem: .metric)
        #expect(text == "25°")
    }
    
    @Test("temperatureText imperial formatting")
    func temperatureTextImperialFormatting() async throws {
        let text = mapper.temperatureText(25, unitSystem: .imperial)
        #expect(text == "77°F")
    }
    
    @Test("temperatureValue metric")
    func temperatureValueMetric() async throws {
        #expect(mapper.temperatureValue(25, unitSystem: .metric) == 25)
    }
    
    @Test("temperatureValue imperial")
    func temperatureValueImperial() async throws {
        let value = mapper.temperatureValue(25, unitSystem: .imperial)
        #expect(value == 77)
    }
    
    @Test("dailyScore ideal conditions returns high score")
    func dailyScoreIdealConditionsReturnsHighScore() async throws {
        let score = mapper.dailyScore(highCelsius: 24, lowCelsius: 16, precipitationChance: 0)
        #expect(score >= 80)
    }
    
    @Test("dailyScore hot day returns lower score")
    func dailyScoreHotDayReturnsLowerScore() async throws {
        let idealScore = mapper.dailyScore(highCelsius: 24, lowCelsius: 16, precipitationChance: 0)
        let hotScore = mapper.dailyScore(highCelsius: 35, lowCelsius: 20, precipitationChance: 0)
        #expect(hotScore < idealScore)
    }
    
    @Test("dailyScore rainy day returns lower score")
    func dailyScoreRainyDayReturnsLowerScore() async throws {
        let dryScore = mapper.dailyScore(highCelsius: 24, lowCelsius: 16, precipitationChance: 0)
        let rainyScore = mapper.dailyScore(highCelsius: 24, lowCelsius: 16, precipitationChance: 0.8)
        #expect(rainyScore < dryScore)
    }
    
    @Test("dailyScore clamped between 0 and 100")
    func dailyScoreClampedBetween0And100() async throws {
        let extremeHot = mapper.dailyScore(highCelsius: 50, lowCelsius: 30, precipitationChance: 0.9)
        #expect(extremeHot >= 0 && extremeHot <= 100)
        
        let extremeCold = mapper.dailyScore(highCelsius: -20, lowCelsius: -30, precipitationChance: 0)
        #expect(extremeCold >= 0 && extremeCold <= 100)
    }
}
