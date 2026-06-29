import Foundation
import ActivityKit

@available(iOS 18.0, *)
public struct WizPathHUDLiveActivityAttributes: ActivityAttributes, Sendable {

    public struct ContentState: Codable, Hashable, Equatable, Sendable {
        public var safetyScore: Int
        public var hazardCount: Int
        public var totalDuration: TimeInterval
        public var distanceRemaining: Double
        public var nextSafeStopName: String?
        public var nextSafeStopEta: Date?
        public var routeRiskLabel: String
        public var weatherConditionSymbol: String
        public var estimatedArrival: Date

        public init(
            safetyScore: Int,
            hazardCount: Int,
            totalDuration: TimeInterval,
            distanceRemaining: Double,
            nextSafeStopName: String?,
            nextSafeStopEta: Date?,
            routeRiskLabel: String,
            weatherConditionSymbol: String,
            estimatedArrival: Date
        ) {
            self.safetyScore = safetyScore
            self.hazardCount = hazardCount
            self.totalDuration = totalDuration
            self.distanceRemaining = distanceRemaining
            self.nextSafeStopName = nextSafeStopName
            self.nextSafeStopEta = nextSafeStopEta
            self.routeRiskLabel = routeRiskLabel
            self.weatherConditionSymbol = weatherConditionSymbol
            self.estimatedArrival = estimatedArrival
        }
    }

    public var routeOriginName: String
    public var routeDestinationName: String
    public var travelModeRaw: String

    public init(
        routeOriginName: String,
        routeDestinationName: String,
        travelModeRaw: String
    ) {
        self.routeOriginName = routeOriginName
        self.routeDestinationName = routeDestinationName
        self.travelModeRaw = travelModeRaw
    }
}
