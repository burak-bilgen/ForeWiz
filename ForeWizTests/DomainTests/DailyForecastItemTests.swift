import Foundation
import Testing
@testable import ForeWiz

struct DailyForecastItemTests {
    @Test func dailyForecastItemIsEquatable() {
        let date = Date()
        let item1 = DailyForecastItem(
            dayName: "Pzt",
            date: date,
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true,
            precipitationChance: 0.1
        )

        let item2 = DailyForecastItem(
            dayName: "Pzt",
            date: date,
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true,
            precipitationChance: 0.1
        )

        #expect(item1 == item2)
    }

    @Test func dailyForecastItemHasUniqueID() {
        let date = Date()
        let nextDate = date.addingTimeInterval(86_400)
        let item1 = DailyForecastItem(
            dayName: "Pzt",
            date: date,
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true,
            precipitationChance: 0.1
        )

        let item2 = DailyForecastItem(
            dayName: "Sal",
            date: nextDate,
            highTemp: 26.0,
            lowTemp: 16.0,
            conditionSymbol: "cloud.sun.fill",
            outdoorScore: 80,
            outdoorDecision: .moderate,
            isToday: false,
            precipitationChance: 0.2
        )

        #expect(item1.id != item2.id)
    }
}
