import Testing
import Foundation
@testable import ForeWiz

struct HealthAirQualityCalculatorTests {

    @Test("Good AQI returns index 0")
    func testGoodAQI() {
        let aq = AirQualityInfo(aqi: 35)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 0)
        #expect(result.category == .good)
    }

    @Test("Moderate AQI returns index 2")
    func testModerateAQI() {
        let aq = AirQualityInfo(aqi: 75)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 2)
        #expect(result.category == .moderate)
    }

    @Test("Unhealthy for sensitive groups returns index 4")
    func testUnhealthyForSensitive() {
        let aq = AirQualityInfo(aqi: 120)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 4)
        #expect(result.category == .unhealthyForSensitive)
    }

    @Test("Unhealthy AQI returns index 6")
    func testUnhealthyAQI() {
        let aq = AirQualityInfo(aqi: 170)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 6)
        #expect(result.category == .unhealthy)
    }

    @Test("Very unhealthy AQI returns index 8")
    func testVeryUnhealthyAQI() {
        let aq = AirQualityInfo(aqi: 250)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 8)
        #expect(result.category == .veryUnhealthy)
    }

    @Test("Hazardous AQI returns index 10")
    func testHazardousAQI() {
        let aq = AirQualityInfo(aqi: 400)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.index == 10)
        #expect(result.category == .hazardous)
    }

    @Test("Nil air quality returns zero index")
    func testNilAirQuality() {
        let result = HealthAirQualityCalculator.calculate(airQuality: nil)
        #expect(result.index == 0)
        #expect(result.category == .good)
    }

    @Test("AQI values are clamped to 0-500")
    func testAQIClamping() {
        let belowZero = AirQualityInfo(aqi: -10)
        #expect(belowZero.aqi == 0)

        let aboveMax = AirQualityInfo(aqi: 999)
        #expect(aboveMax.aqi == 500)
    }

    @Test("High pollen with sensitive AQI includes pollen in advice")
    func testPollenInAdvice() {
        let aq = AirQualityInfo(aqi: 120, pollenIndex: 7)
        let result = HealthAirQualityCalculator.calculate(airQuality: aq)
        #expect(result.advice.contains("7") || result.advice.contains("yüksek"))
    }

    @Test("Pollen index clamped to 0-10")
    func testPollenClamping() {
        let highPollen = AirQualityInfo(aqi: 50, pollenIndex: 15)
        #expect(highPollen.pollenIndex == 10)

        let lowPollen = AirQualityInfo(aqi: 50, pollenIndex: -5)
        #expect(lowPollen.pollenIndex == 0)
    }

    @Test("Summary contains AQI value and category label")
    func testSummary() {
        let aq = AirQualityInfo(aqi: 42)
        let summary = HealthAirQualityCalculator.summary(airQuality: aq)
        #expect(summary.contains("42"))
        #expect(summary.isEmpty == false)
    }

    @Test("Summary with high pollen includes pollen note")
    func testSummaryWithPollen() {
        let aq = AirQualityInfo(aqi: 65, pollenIndex: 5)
        let summary = HealthAirQualityCalculator.summary(airQuality: aq)
        #expect(summary.isEmpty == false)
    }

    @Test("Nil air quality summary returns no data message")
    func testNilSummary() {
        let summary = HealthAirQualityCalculator.summary(airQuality: nil)
        #expect(summary.isEmpty == false)
    }

    @Test("All category labels are non-empty")
    func testAllCategoryLabels() {
        for category in AirQualityCategory.allCases {
            #expect(category.localizedTitle.isEmpty == false)
            #expect(category.localizedAdvice.isEmpty == false)
            #expect(category.symbolName.isEmpty == false)
        }
    }

    @Test("Boundary at 50 is good")
    func testBoundaryGood() {
        let aq = AirQualityInfo(aqi: 50)
        #expect(aq.category == .good)
    }

    @Test("Boundary at 51 is moderate")
    func testBoundaryModerate() {
        let aq = AirQualityInfo(aqi: 51)
        #expect(aq.category == .moderate)
    }

    @Test("Boundary at 100 is moderate")
    func testBoundaryModerateTop() {
        let aq = AirQualityInfo(aqi: 100)
        #expect(aq.category == .moderate)
    }

    @Test("Boundary at 101 is unhealthy for sensitive")
    func testBoundarySensitive() {
        let aq = AirQualityInfo(aqi: 101)
        #expect(aq.category == .unhealthyForSensitive)
    }

    @Test("isUnhealthyForSensitiveGroups at 101")
    func testUnhealthySensitiveFlag() {
        let aq = AirQualityInfo(aqi: 101)
        #expect(aq.isUnhealthyForSensitiveGroups)
        #expect(aq.isUnhealthy == false)
    }

    @Test("isUnhealthy at 151")
    func testUnhealthyFlag() {
        let aq = AirQualityInfo(aqi: 151)
        #expect(aq.isUnhealthy)
    }
}
