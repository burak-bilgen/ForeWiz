import Foundation
import Testing
@testable import ForeWiz

@Suite("WeatherPresentationMapper Tests", .serialized)
struct WeatherPresentationMapperTests {
    
    private let mapper = WeatherPresentationMapper()
    
    @Test("conditionText maps thunderstorm")
    func conditionTextMapsThunderstorm() async throws {
        let t1 = mapper.conditionText(for: "Thunderstorm")
        #expect(t1 == L10n.text("weather_storm", lang: "tr") || t1 == L10n.text("weather_storm", lang: "en"))
        
        let t2 = mapper.conditionText(for: "Thunder")
        #expect(t2 == L10n.text("weather_storm", lang: "tr") || t2 == L10n.text("weather_storm", lang: "en"))
    }
    
    @Test("conditionText maps rain")
    func conditionTextMapsRain() async throws {
        let t1 = mapper.conditionText(for: "Rain")
        #expect(t1 == L10n.text("weather_rain", lang: "tr") || t1 == L10n.text("weather_rain", lang: "en"))
        
        let t2 = mapper.conditionText(for: "Drizzle")
        #expect(t2 == L10n.text("weather_rain", lang: "tr") || t2 == L10n.text("weather_rain", lang: "en"))
    }
    
    @Test("conditionText maps snow")
    func conditionTextMapsSnow() async throws {
        let t1 = mapper.conditionText(for: "Snow")
        #expect(t1 == L10n.text("weather_snow", lang: "tr") || t1 == L10n.text("weather_snow", lang: "en"))
        
        let t2 = mapper.conditionText(for: "Sleet")
        #expect(t2 == L10n.text("weather_snow", lang: "tr") || t2 == L10n.text("weather_snow", lang: "en"))
    }
    
    @Test("conditionText maps cloudy")
    func conditionTextMapsCloudy() async throws {
        let t1 = mapper.conditionText(for: "Cloudy")
        #expect(t1 == L10n.text("weather_cloudy", lang: "tr") || t1 == L10n.text("weather_cloudy", lang: "en"))
        
        let t2 = mapper.conditionText(for: "MostlyCloudy")
        #expect(t2 == L10n.text("weather_cloudy", lang: "tr") || t2 == L10n.text("weather_cloudy", lang: "en"))
    }
    
    @Test("conditionText maps fog")
    func conditionTextMapsFog() async throws {
        let t1 = mapper.conditionText(for: "Fog")
        #expect(t1 == L10n.text("weather_foggy", lang: "tr") || t1 == L10n.text("weather_foggy", lang: "en"))
        
        let t2 = mapper.conditionText(for: "Haze")
        #expect(t2 == L10n.text("weather_foggy", lang: "tr") || t2 == L10n.text("weather_foggy", lang: "en"))
    }
    
    @Test("conditionText maps clear")
    func conditionTextMapsClear() async throws {
        let t1 = mapper.conditionText(for: "Clear")
        #expect(t1 == L10n.text("weather_clear", lang: "tr") || t1 == L10n.text("weather_clear", lang: "en"))
        
        let t2 = mapper.conditionText(for: "Sun")
        #expect(t2 == L10n.text("weather_clear", lang: "tr") || t2 == L10n.text("weather_clear", lang: "en"))
    }
    
    @Test("conditionText returns default for unknown")
    func conditionTextReturnsDefaultForUnknown() async throws {
        let t1 = mapper.conditionText(for: nil)
        #expect(t1 == L10n.text("weather_current", lang: "tr") || t1 == L10n.text("weather_current", lang: "en"))
        
        let t2 = mapper.conditionText(for: "UnknownCondition")
        #expect(t2 == L10n.text("weather_current", lang: "tr") || t2 == L10n.text("weather_current", lang: "en"))
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
