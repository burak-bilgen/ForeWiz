import Testing
@testable import Weathra

struct DailyForecastItemTests {
    @Test func dailyForecastItemIsEquatable() {
        let item1 = DailyForecastItem(
            dayName: "Pzt",
            date: Date(),
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true
        )

        let item2 = DailyForecastItem(
            dayName: "Pzt",
            date: Date(),
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true
        )

        #expect(item1 == item2)
    }

    @Test func dailyForecastItemHasUniqueID() {
        let item1 = DailyForecastItem(
            dayName: "Pzt",
            date: Date(),
            highTemp: 25.0,
            lowTemp: 15.0,
            conditionSymbol: "sun.max.fill",
            outdoorScore: 85,
            outdoorDecision: .good,
            isToday: true
        )

        let item2 = DailyForecastItem(
            dayName: "Sal",
            date: Date(),
            highTemp: 26.0,
            lowTemp: 16.0,
            conditionSymbol: "cloud.sun.fill",
            outdoorScore: 80,
            outdoorDecision: .moderate,
            isToday: false
        )

        #expect(item1.id != item2.id)
    }
}
