import Foundation

struct HomeViewState: Equatable {
    let recommendation: DailyRecommendation
    let assistant: HomeAssistantViewState
    let plan: HomePlanViewState
    let currentWeather: HomeCurrentWeatherViewState
    let dailyForecasts: [DailyForecastItem]
    let hourlyScores: [HourlyScoreItem]
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool
    let warningMessage: String?
    let heatSafetyBanner: HeatSafetyBanner?
    let heatStreakCount: Int
    let briefing: DailyWeatherBriefing?
    let attribution: WeatherAttributionInfo?
}

struct HomePlanViewState: Equatable {
    let title: String
    let subtitle: String
    let items: [HomePlanItem]
}

struct HomePlanItem: Equatable, Identifiable {
    let id: String
    let icon: String
    let title: String
    let timeText: String
    let detail: String
    let tone: HomeAssistantTone
    let isPrimary: Bool
}

struct HomeAssistantViewState: Equatable {
    let headline: String
    let summary: String
    let primaryActionTitle: String
    let primaryActionDetail: String
    let symbolName: String
    let tone: HomeAssistantTone
    let criticalAlert: HomeAssistantSignal?
}

struct HomeAssistantSignal: Equatable, Identifiable {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let hint: String
    let tone: HomeAssistantTone
}

enum HomeAssistantTone: String, Equatable {
    case good
    case caution
    case danger
    case info
}

struct HourlyScoreItem: Equatable, Identifiable {
    var id: Date { date }

    let date: Date
    let hour: Int
    let score: Int
    let symbolName: String
    let temperatureText: String
    let precipitationChance: Double
}

// MARK: - Heat Safety Banner

struct HeatSafetyBanner: Equatable, Identifiable {
    let id: String = "heat-safety"
    let severity: RiskLevel
    let currentTemp: Double
    let adviceKey: String

    var iconName: String {
        switch severity {
        case .extreme: "thermometer.sun.triangle.fill"
        case .high: "thermometer.sun.fill"
        default: "sun.max.trianglebadge.exclamationmark.fill"
        }
    }

    var titleKey: String {
        switch severity {
        case .extreme: "heat_banner_critical_title"
        case .high: "heat_banner_high_title"
        default: "heat_banner_warning_title"
        }
    }

    var messageKey: String {
        adviceKey
    }
}

struct HomeCurrentWeatherViewState: Equatable {
    let temperatureText: String
    let feelsLikeText: String
    let conditionText: String
    let symbolName: String
    let humidityText: String
    let windText: String
    let uvIndexText: String
    let highTempText: String
    let lowTempText: String
    let sunriseText: String?
    let sunsetText: String?
}
