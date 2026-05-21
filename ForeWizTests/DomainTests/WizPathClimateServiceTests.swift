import Foundation
import Testing
import CoreLocation
@testable import ForeWiz

@MainActor
@Suite("WizPathClimateService Tests")
struct WizPathClimateServiceTests {
    
    @Test("analyzeRouteClimate detects extreme heat")
    func analyzeRouteClimateDetectsExtremeHeat() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .clear,
                    temperature: 42,
                    precipitationChance: 0,
                    windSpeed: 5,
                    visibility: 10,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        
        #expect(analysis.maxTemperature == 42)
        #expect(analysis.isExtremeHeat == true)
        #expect(analysis.requiresClimateAdjustment == true)
        #expect(analysis.totalMultiplier > 1.0)
    }
    
    @Test("analyzeRouteClimate generates EV battery alert for car in extreme heat")
    func analyzeRouteClimateGeneratesEVBatteryAlertForCarInExtremeHeat() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .clear,
                    temperature: 40,
                    precipitationChance: 0,
                    windSpeed: 5,
                    visibility: 10,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        
        #expect(analysis.alerts.contains { $0.type == .evBatteryEfficiency })
    }
    
    @Test("analyzeRouteClimate generates heat stroke alert for walking in extreme heat")
    func analyzeRouteClimateGeneratesHeatStrokeAlertForWalkingInExtremeHeat() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .clear,
                    temperature: 40,
                    precipitationChance: 0,
                    windSpeed: 5,
                    visibility: 10,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .walking,
            departureTime: now,
            segments: segments,
            totalDuration: 3600,
            totalDistance: 5000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .walking)
        
        #expect(analysis.alerts.contains { $0.type == .heatStrokeRisk })
    }
    
    @Test("analyzeRouteClimate detects thunderstorm and applies multiplier")
    func analyzeRouteClimateDetectsThunderstormAndAppliesMultiplier() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .thunderstorm,
                    temperature: 20,
                    precipitationChance: 0.9,
                    windSpeed: 50,
                    visibility: 3,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        
        #expect(analysis.multipliers.contains { $0.type == .severeStorm })
        #expect(analysis.totalMultiplier >= WizPathClimateService.ClimateMultipliers.severeStorm)
    }
    
    @Test("analyzeRouteClimate detects heavy rain and applies multiplier")
    func analyzeRouteClimateDetectsHeavyRainAndAppliesMultiplier() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .heavyRain,
                    temperature: 18,
                    precipitationChance: 0.95,
                    windSpeed: 30,
                    visibility: 4,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        
        #expect(analysis.multipliers.contains { $0.type == .heavyRain })
    }
    
    @Test("analyzeRouteClimate returns no adjustments for clear weather")
    func analyzeRouteClimateReturnsNoAdjustmentsForClearWeather() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 0,
                weather: SegmentWeather(
                    condition: .clear,
                    temperature: 25,
                    precipitationChance: 0,
                    windSpeed: 5,
                    visibility: 15,
                    severity: .good
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        
        #expect(analysis.requiresClimateAdjustment == false)
        #expect(analysis.totalMultiplier == 1.0)
        #expect(analysis.alerts.isEmpty)
    }
    
    @Test("applyClimateAdjustment increases ETA correctly")
    func applyClimateAdjustmentIncreasesETACorrectly() async throws {
        let service = WizPathClimateService()
        
        let now = Date()
        let segments = [
            WizPathSegment(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
                estimatedArrival: now,
                distanceFromStart: 0,
                travelTime: 900,
                weather: SegmentWeather(
                    condition: .clear,
                    temperature: 42,
                    precipitationChance: 0,
                    windSpeed: 5,
                    visibility: 10,
                    severity: .severe
                )
            )
        ]
        
        let route = WizPathRoute(
            id: UUID(),
            origin: CLLocationCoordinate2D(latitude: 41.0, longitude: 29.0),
            destination: CLLocationCoordinate2D(latitude: 42.0, longitude: 30.0),
            travelMode: .car,
            departureTime: now,
            segments: segments,
            totalDuration: 1800,
            totalDistance: 15000,
            polyline: nil
        )
        
        let analysis = service.analyzeRouteClimate(route, travelMode: .car)
        let adjusted = service.applyClimateAdjustment(to: route, analysis: analysis)
        
        #expect(adjusted.adjustedDuration > route.totalDuration)
        #expect(adjusted.addedTime > 0)
        #expect(adjusted.multiplier > 1.0)
    }
    
    @Test("getHeatHealthRecommendations returns recommendations for walking in heat")
    func getHeatHealthRecommendationsReturnsRecommendationsForWalkingInHeat() async throws {
        let service = WizPathClimateService()
        
        let recommendations = service.getHeatHealthRecommendations(
            temperature: 38,
            travelMode: .walking
        )
        
        #expect(!recommendations.isEmpty)
        #expect(recommendations.contains { $0.title.contains("Hydration") || $0.icon == "drop.fill" })
    }
    
    @Test("getEVRecommendations returns recommendations for EV in heat")
    func getEVRecommendationsReturnsRecommendationsForEVInHeat() async throws {
        let service = WizPathClimateService()
        
        let recommendations = service.getEVRecommendations(temperature: 40)
        
        #expect(!recommendations.isEmpty)
    }
    
    @Test("getEVRecommendations returns empty for normal temperature")
    func getEVRecommendationsReturnsEmptyForNormalTemperature() async throws {
        let service = WizPathClimateService()
        
        let recommendations = service.getEVRecommendations(temperature: 25)
        
        #expect(recommendations.isEmpty)
    }
    
    @Test("ClimateAnalysis isCriticalHeat detection")
    func climateAnalysisIsCriticalHeatDetection() async throws {
        let analysis = ClimateAnalysis(
            maxTemperature: 46,
            totalMultiplier: 1.25,
            multipliers: [],
            alerts: [],
            heatSegments: [],
            requiresClimateAdjustment: true
        )
        
        #expect(analysis.isExtremeHeat == true)
        #expect(analysis.isCriticalHeat == true)
    }
    
    @Test("TemperatureThresholds constants")
    func temperatureThresholdsConstants() async throws {
        #expect(WizPathClimateService.TemperatureThresholds.evEfficiencyReduction == 38.0)
        #expect(WizPathClimateService.TemperatureThresholds.pedestrianHeatRisk == 36.0)
        #expect(WizPathClimateService.TemperatureThresholds.extremeHeat == 40.0)
        #expect(WizPathClimateService.TemperatureThresholds.criticalHeat == 45.0)
    }
}
