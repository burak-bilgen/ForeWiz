import Foundation
import CoreLocation

// MARK: - WizPath View State

public enum WizPathViewState: Equatable {
    case idle
    case calculating
    case routeReady(WizPathRoute)
    case error(String)
    case offline

    public static func == (lhs: WizPathViewState, rhs: WizPathViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.calculating, .calculating), (.offline, .offline): return true
        case (.routeReady(let l), .routeReady(let r)): return l.id == r.id
        case (.error(let l), .error(let r)): return l == r
        default: return false
        }
    }

    public var isIdle: Bool { if case .idle = self { return true }; return false }
    public var isCalculating: Bool { if case .calculating = self { return true }; return false }
    public var isOffline: Bool { if case .offline = self { return true }; return false }
    public var route: WizPathRoute? { if case .routeReady(let r) = self { return r }; return nil }
    public var errorMessage: String? { if case .error(let m) = self { return m }; return nil }
}

// MARK: - Route Status (for HUD)

public enum RouteStatus: Equatable {
    case optimal(destination: String, eta: String)
    case warning(destination: String, hazard: String, eta: String)
    case critical(destination: String, hazard: String)
    case noRoute

    public var iconName: String {
        switch self {
        case .optimal: return "car.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        case .noRoute: return "mappin.and.ellipse"
        }
    }
}

// MARK: - HUD Status (shared observable)

@Observable
public final class WizPathHUDStatus {
    nonisolated(unsafe) public static let shared = WizPathHUDStatus()
    public var currentStatus: RouteStatus = .noRoute
    private init() {}
}

// MARK: - WizPath ViewModel

@MainActor
@Observable
public final class WizPathViewModel {
    // MARK: - Dependencies
    private let wizPathService: WizPathService
    private let departureOptimizerService: DepartureOptimizerService?
    private let climateService = WizPathClimateService.shared
    private let sentinelService = WizPathSentinelService.shared
    private let cyclingSafetyService = WizPathCyclingSafetyService.shared
    private let poiSearchService = POISearchService.shared

    // MARK: - State
    public var state: WizPathViewState = .idle
    public var travelMode: TravelMode = .car
    public var departureTime: Date = {
        // Default to next hour, clamped to today/tomorrow
        let now = Date()
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        return nextHour
    }()
    public var destinationName: String = ""
    public var destinationCoordinate: CLLocationCoordinate2D?
    public var originCoordinate: CLLocationCoordinate2D?
    public var originName: String = WizPathKitL10n.text("wizpath_current_location")
    public var recentDestinations: [RecentDestination] = []
    public var isShowingRoute = true
    public var showJourneyHUD = false
    public var climateAnalysis: ClimateAnalysis?
    public var routeStatusForHUD: RouteStatus = .noRoute
    public var sentinelAlerts: [SentinelAlert] = []
    public var isOnline = true
    public var bestDepartureTime: Date?
    public var departureTimeReason: String?
    public var cyclingSafetyAnalysis: WizPathCyclingSafetyService.CyclingSafetyAnalysis?
    public var cyclingSafetyRecommendations: [HealthRecommendation] = []
    public var isElectricVehicle = false
    public var evRecommendations: [EVRecommendation] = []
    public var chargingStations: [SmartStop] = []
    public var isLoadingMapDetails = false

    // MARK: - Route Comparison & Preferences
    /// All scored route candidates from the latest calculation
    public var routeCandidates: [ScoredRouteCandidate] = []
    /// Index into routeCandidates for the currently selected route
    public var selectedRouteIndex: Int = 0
    /// Whether to avoid toll roads in route calculation
    public var avoidTollRoads = false
    /// Traffic congestion info for the current route
    public var currentTrafficCongestion: TrafficCongestionLevel = .unknown
    public var hasTollRoads: Bool = false
    /// Whether the route comparison panel is expanded
    public var showRouteComparison = false
    /// Map presentation: compact (small preview) vs expanded (half screen)
    public var mapExpanded = false
    /// Whether traffic overlay is shown on the map
    public var showTrafficOnMap = false

    // MARK: - Waypoint Selection
    /// IDs of waypoints the user wants to include when navigating to Maps.
    /// - `nil`: include all available waypoints (default for backward compat)
    /// - `[]` (empty): include no waypoints (navigate directly)
    /// - Non-empty: include only the specified waypoints
    public var selectedWaypointIds: Set<UUID>? = nil

    /// Waypoints filtered by user selection.
    /// Returns all available waypoints when selectedWaypointIds is nil (= all selected).
    /// Returns empty when selectedWaypointIds is empty (navigate directly).
    public var selectedMapsWaypoints: [SmartStop] {
        let all = mapsWaypoints
        guard let ids = selectedWaypointIds else { return all }
        return all.filter { ids.contains($0.id) }
    }

    // MARK: - Internal State
    private var lastCalculatedRoute: WizPathRoute?
    /// Timestamp when lastCalculatedRoute was saved, used for cache expiration.
    /// Internal for test access.
    var lastCalculatedRouteTimestamp: Date?
    /// Routes older than this interval are considered stale and won't be used offline.
    let cacheExpirationInterval: TimeInterval = 1800 // 30 minutes
    public var didLoadInitialLocation = false
    // Auto-refresh timer for traffic updates
    private var refreshTimer: Task<Void, Never>?
    private var chargingStationsTask: Task<Void, Never>?
    private var placeNameTask: Task<Void, Never>?
    private var isAutoRefreshing = false
    public var selectedWeatherSegment: WizPathSegment?
    public var showWeatherDetail = false
    public var selectedChargingStation: SmartStop?
    public var showChargingStationDetail = false
    /// Resolved place names for weather change point segments (segment.id → place name)
    public var segmentPlaceNames: [UUID: String] = [:]

    // MARK: - Computed
    public var canCalculate: Bool { destinationCoordinate != nil && !state.isCalculating && isOnline }
    public var currentRoute: WizPathRoute? { state.route }
    public var isCalculating: Bool { state.isCalculating }
    public var errorMessage: String? { state.errorMessage }
    public var routeSegments: [WizPathSegment] { currentRoute?.segments ?? [] }
    public var weatherChangePoints: [WizPathSegment] { currentRoute?.weatherChangePoints ?? [] }
    public var overallRisk: RouteRisk { currentRoute?.overallRisk ?? .good }

    /// The route to use for maps navigation — falls back to the last
    /// successfully calculated route when offline or in error state.
    /// This ensures users can always navigate to their destination
    /// in Apple/Google Maps even without an active connection.
    /// If the cached route is older than cacheExpirationInterval,
    /// it is considered stale and returns nil to avoid showing outdated data.
    public var mapsNavigationRoute: WizPathRoute? {
        if let route = currentRoute { return route }
        guard let cached = lastCalculatedRoute,
              let timestamp = lastCalculatedRouteTimestamp else { return nil }
        // Cache is fresh enough — use it
        if Date().timeIntervalSince(timestamp) < cacheExpirationInterval {
            return cached
        }
        // Cache expired — treat as no route
        return nil
    }

    /// Waypoints for maps navigation, filtered by safety and sorted by
    /// estimated arrival time so stops appear in logical route order.
    /// This provides a seamless navigation experience with relevant
    /// charging stations, gas stations, and rest stops along the way.
    public var mapsWaypoints: [SmartStop] {
        chargingStations
            .filter { !$0.safetyStatus.shouldAvoid }
            .sorted { $0.etaArrival < $1.etaArrival }
    }

    // MARK: - Init
    public init(wizPathService: WizPathService, departureOptimizerService: DepartureOptimizerService? = nil) {
        self.wizPathService = wizPathService
        self.departureOptimizerService = departureOptimizerService
        loadCurrentLocation()
        loadRecentDestinations()
    }

    // MARK: - Location

    public func loadCurrentLocation() {
        Task {
            do {
                let locationCoord = try await wizPathService.getCurrentLocation()
                originCoordinate = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)
                didLoadInitialLocation = true
                AppLogger.wizPath.info("Location loaded")
            } catch {
                AppLogger.wizPath.error("Location error: \(error.localizedDescription)")
                originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
                originName = WizPathKitL10n.text("wizpath_fallback_location")
                didLoadInitialLocation = true
            }
        }
    }

    public func setDestination(coordinate: CLLocationCoordinate2D, name: String) {
        destinationCoordinate = coordinate
        destinationName = name
        state = .idle
        wizPathService.saveRecentDestination(name: name, coordinate: coordinate)
        loadRecentDestinations()
        Task { await calculateRoute() }
    }

    // MARK: - Recent Destinations

    public func loadRecentDestinations() {
        recentDestinations = wizPathService.loadRecentDestinations()
    }

    public func selectRecentDestination(_ recent: RecentDestination) {
        setDestination(coordinate: recent.coordinate, name: recent.name)
    }

    // MARK: - Route Calculation

    public func selectRouteCandidate(at index: Int) {
        guard index >= 0, index < routeCandidates.count else { return }
        selectedRouteIndex = index
        let candidate = routeCandidates[index]
        state = .routeReady(candidate.route)
        lastCalculatedRoute = candidate.route
        lastCalculatedRouteTimestamp = Date()
        currentTrafficCongestion = candidate.trafficCongestion
        hasTollRoads = candidate.hasTollRoads
        showRouteComparison = false
        updateRouteStatus(for: candidate.route)
        showJourneyHUD = true
        HapticEngine.shared.selectionChanged()
        AppLogger.wizPath.info("Switched to route candidate #\(index): score=\(candidate.score)")
    }

    public func toggleAvoidTollRoads() {
        avoidTollRoads.toggle()
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func calculateRoute() async {
        guard isOnline else {
            // During auto-refresh, only keep the cached route if it's still fresh
            if isAutoRefreshing,
               let lastRoute = lastCalculatedRoute,
               let timestamp = lastCalculatedRouteTimestamp,
               Date().timeIntervalSince(timestamp) < cacheExpirationInterval {
                state = .routeReady(lastRoute)
            } else {
                state = .offline
            }
            isAutoRefreshing = false
            return
        }
        guard let origin = originCoordinate, let destination = destinationCoordinate else {
            if isAutoRefreshing, let lastRoute = lastCalculatedRoute {
                state = .routeReady(lastRoute)
            } else {
                state = .error(WizPathKitL10n.text("wizpath_error_no_destination"))
            }
            isAutoRefreshing = false
            return
        }
        state = .calculating
        if !isAutoRefreshing { HapticEngine.shared.medium() }
        do {
            let result = try await wizPathService.calculateRouteWithCandidates(
                origin: origin,
                destination: destination,
                mode: travelMode,
                departureTime: departureTime,
                avoidTollRoads: avoidTollRoads
            )
            let route = result.best
            routeCandidates = result.candidates
            selectedRouteIndex = 0

            // Extract traffic/toll info from the best candidate
            if let bestCandidate = result.candidates.first {
                currentTrafficCongestion = bestCandidate.trafficCongestion
                hasTollRoads = bestCandidate.hasTollRoads
            } else {
                currentTrafficCongestion = .unknown
                hasTollRoads = false
            }
            climateAnalysis = climateService.analyzeRouteClimate(route, travelMode: travelMode)
                // Analyze cycling safety if applicable
            if travelMode == .cycling {
                cyclingSafetyAnalysis = cyclingSafetyService.analyzeCyclingSafety(route: route)
                // Add health recommendations from climate service (hydration, crosswind, wet roads)
                let winds = route.segments.compactMap { $0.weather?.windSpeed }
                let temps = route.segments.compactMap { $0.weather?.temperature }
                let precips = route.segments.compactMap { $0.weather?.precipitationChance }
                let avgWind = winds.reduce(0, +) / Double(max(1, winds.count))
                let avgTemp = temps.reduce(0, +) / Double(max(1, temps.count))
                let maxPrecip = precips.max() ?? 0
                cyclingSafetyRecommendations = climateService.getCyclingSafetyRecommendations(
                    windSpeed: avgWind,
                    temperature: avgTemp,
                    precipitationChance: maxPrecip
                )
            } else {
                cyclingSafetyAnalysis = nil
                cyclingSafetyRecommendations = []
            }

            // Compute EV recommendations only when the car is marked as electric.
            if travelMode == .car, isElectricVehicle, let maxTemp = climateAnalysis?.maxTemperature {
                evRecommendations = climateService.getEVRecommendations(temperature: maxTemp)
            } else {
                evRecommendations = []
            }

            if let previousRoute = lastCalculatedRoute {
                let routeConditions = route.segments.compactMap { $0.weather?.condition }
                let worstCondition = routeConditions.max(by: { $0.severity.severityOrder < $1.severity.severityOrder })
                let primaryHazard: WeatherHazardType? = {
                    switch worstCondition {
                    case .thunderstorm: return .severeStorm
                    case .heavyRain: return .flooding
                    case .snow, .sleet:
                        let temperatures = route.segments.compactMap { $0.weather?.temperature }
                        let avgTemp = temperatures.reduce(0.0, +) / Double(max(1, temperatures.count))
                        return avgTemp < 0 ? .blizzard : .heavySnow
                    default:
                        return climateAnalysis?.isExtremeHeat == true ? .extremeHeat : nil
                    }
                }()
                let weatherContext = WeatherContext(primaryHazard: primaryHazard, temperature: climateAnalysis?.maxTemperature, conditions: routeConditions, isExtreme: climateAnalysis?.isExtremeHeat ?? false)
                let decision = sentinelService.evaluateRouteChange(originalRoute: previousRoute, updatedRoute: route, weatherContext: weatherContext)
                if case .trigger(let alert) = decision {
                    sentinelAlerts.append(alert)
                    await sentinelService.dispatchSentinelAlert(alert)
                }
            }
            lastCalculatedRoute = route
            lastCalculatedRouteTimestamp = Date()
            updateRouteStatus(for: route)
            await analyzeBestDepartureTime(route: route)
            state = .routeReady(route)
            showJourneyHUD = true
            refreshChargingStations(for: route)
            if !isAutoRefreshing { HapticEngine.shared.success() }
            startAutoRefresh()
            resolvePlaceNames(for: route)
            AppLogger.wizPath.info("Route calculated: \(route.totalDuration)s, risk: \(route.overallRisk.rawValue)")
        } catch let error as WizPathError {
            if isAutoRefreshing {
                AppLogger.wizPath.warning("Auto-refresh failed (keeping old route): \(error.localizedDescription)")
                if let lastRoute = lastCalculatedRoute {
                    state = .routeReady(lastRoute)
                }
            } else {
                state = .error(error.localizedDescription)
                HapticEngine.shared.warning()
            }
        } catch {
            AppLogger.wizPath.error("Route calculation failed: \(error.localizedDescription)")
            if isAutoRefreshing {
                AppLogger.wizPath.warning("Auto-refresh failed (keeping old route): \(error.localizedDescription)")
                if let lastRoute = lastCalculatedRoute {
                    state = .routeReady(lastRoute)
                }
            } else {
                state = .error(WizPathKitL10n.text("wizpath_error_route_failed"))
                HapticEngine.shared.error()
            }
        }
        isAutoRefreshing = false
    }

    // MARK: - Departure Time Optimization

    private func analyzeBestDepartureTime(route: WizPathRoute) async {
        guard !route.segments.isEmpty else { return }
        guard let optimizer = departureOptimizerService else { return }
        let now = Date()
        let sixHoursLater = now.addingTimeInterval(6 * 3600)
        
        guard let origin = originCoordinate, let destination = destinationCoordinate else { return }
        
        do {
            let result = try await optimizer.findOptimalDepartureTime(
                origin: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude),
                destination: CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude),
                travelMode: route.travelMode,
                earliestDeparture: now,
                latestDeparture: sixHoursLater
            )
            
            // Only suggest if the best time is in the future
            guard result.bestDepartureTime > now else { return }
            
            self.bestDepartureTime = result.bestDepartureTime
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            
            let bestWindow = result.scoredWindows.first
            if bestWindow?.recommendation == .optimal || bestWindow?.recommendation == .good {
                departureTimeReason = WizPathKitL10n.formatted(
                    "wizpath_weather_improving",
                    formatter.string(from: result.bestDepartureTime)
                )
            } else if let score = bestWindow?.totalScore {
                departureTimeReason = WizPathKitL10n.formatted(
                    "wizpath_best_score",
                    score
                )
            }
        } catch {
            AppLogger.wizPath.error("Departure optimization failed: \(error.localizedDescription)")
            // Silent fallback — bestDepartureTime stays nil
        }
    }

    // MARK: - Actions

    public func switchTravelMode(to mode: TravelMode) {
        travelMode = mode
        // Reset cycling analysis when switching modes
        if mode != .cycling {
            cyclingSafetyAnalysis = nil
            cyclingSafetyRecommendations = []
        }
        if mode != .car {
            isElectricVehicle = false
            evRecommendations = []
        }
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func updateDepartureTime(_ date: Date) {
        // Clamp to future: if the selected time is in the past, advance to tomorrow at the same time
        let now = Date()
        let finalDate: Date
        if date <= now {
            let calendar = Calendar.current
            finalDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            AppLogger.wizPath.info("Departure time was in the past, advanced to tomorrow: \(finalDate)")
        } else {
            finalDate = date
        }
        departureTime = finalDate
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func refreshRoute() {
        HapticEngine.shared.weatherRefresh()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func reset() {
        refreshTimer?.cancel()
        refreshTimer = nil
        chargingStationsTask?.cancel()
        chargingStationsTask = nil
        placeNameTask?.cancel()
        placeNameTask = nil
        lastCalculatedRoute = nil
        lastCalculatedRouteTimestamp = nil
        selectedWaypointIds = nil
        state = .idle
        destinationCoordinate = nil
        destinationName = ""
        showJourneyHUD = false
        showWeatherDetail = false
        selectedWeatherSegment = nil
        selectedChargingStation = nil
        showChargingStationDetail = false
        isElectricVehicle = false
        evRecommendations = []
        chargingStations = []
        segmentPlaceNames = [:]
        routeCandidates = []
        selectedRouteIndex = 0
        currentTrafficCongestion = .unknown
        hasTollRoads = false
        showRouteComparison = false
        mapExpanded = false
        showTrafficOnMap = false
        HapticEngine.shared.light()
    }

    public func setElectricVehicleEnabled(_ enabled: Bool) {
        guard isElectricVehicle != enabled else { return }
        // EV mode is only valid for car travel — reject enable for other modes
        guard travelMode == .car || !enabled else { return }
        isElectricVehicle = enabled
        updateElectricVehicleContent()
        HapticEngine.shared.selectionChanged()
    }

    // MARK: - Route Annotations

    private func updateElectricVehicleContent() {
        if travelMode == .car, isElectricVehicle, let maxTemp = climateAnalysis?.maxTemperature {
            evRecommendations = climateService.getEVRecommendations(temperature: maxTemp)
        } else {
            evRecommendations = []
        }
        if let route = currentRoute {
            refreshChargingStations(for: route)
        }
    }

    private func refreshChargingStations(for route: WizPathRoute) {
        isLoadingMapDetails = true
        chargingStationsTask?.cancel()
        chargingStations = []

        let categories: [POICategory]
        switch travelMode {
        case .car:
            if isElectricVehicle {
                categories = [.evCharger, .restStop]
            } else {
                categories = [.gasStation, .restStop]
            }
        case .cycling, .walking:
            categories = [.restStop, .restaurant]
        }

        let routeID = route.id
        chargingStationsTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoadingMapDetails = false }
            let foundStops = await self.poiSearchService.searchSmartStopsAlongRoute(route: route, categories: categories)
            
            guard !Task.isCancelled,
                  self.currentRoute?.id == routeID else { return }
                  
            var enrichedStops: [SmartStop] = []
            for stop in foundStops {
                let weatherAtArrival = self.findArrivalWeather(for: stop.coordinate, in: route)
                let safetyStatus = self.computeStopSafetyStatus(weather: weatherAtArrival)
                let recommendation = self.generateWeatherRecommendation(
                    category: stop.category,
                    weather: weatherAtArrival,
                    mode: self.travelMode
                )
                
                let enriched = SmartStop(
                    id: stop.id,
                    mapItem: stop.mapItem,
                    coordinate: stop.coordinate,
                    name: stop.name,
                    category: stop.category,
                    etaArrival: stop.etaArrival,
                    weatherAtArrival: weatherAtArrival,
                    safetyStatus: safetyStatus,
                    distanceFromRoute: stop.distanceFromRoute,
                    estimatedStopDuration: stop.estimatedStopDuration,
                    weatherRecommendation: recommendation
                )
                enrichedStops.append(enriched)
            }
            
            self.chargingStations = enrichedStops
        }
    }

    // MARK: - Smart Stop Helpers

    private func findArrivalWeather(for coordinate: CLLocationCoordinate2D, in route: WizPathRoute) -> SegmentWeather? {
        let stopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let closestSegment = route.segments.min(by: {
            let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return stopLocation.distance(from: locA) < stopLocation.distance(from: locB)
        })
        return closestSegment?.weather
    }

    private func computeStopSafetyStatus(weather: SegmentWeather?) -> POISafetyStatus {
        guard let weather = weather else { return .safe }
        switch weather.severity {
        case .good: return .safe
        case .fair: return .safe
        case .caution: return .caution
        case .severe: return .unsafe
        }
    }

    private func generateWeatherRecommendation(category: POICategory, weather: SegmentWeather?, mode: TravelMode) -> String? {
        guard let weather = weather else { return nil }
        
        switch weather.condition {
        case .thunderstorm, .heavyRain, .snow, .sleet:
            switch category {
            case .restStop, .restaurant:
                return WizPathKitL10n.text("wizpath_rec_severe_shelter")
            default:
                return WizPathKitL10n.text("wizpath_rec_severe_wait")
            }
        case .windy:
            if mode == .cycling || mode == .walking {
                return WizPathKitL10n.text("wizpath_rec_strong_wind_stop")
            }
        case .rain:
            return WizPathKitL10n.text("wizpath_rec_rain_break")
        default:
            if weather.temperature >= 28.0 {
                return WizPathKitL10n.formatted("wizpath_rec_high_temp", Int(weather.temperature))
            }
        }
        return nil
    }

    private func resolvePlaceNames(for route: WizPathRoute) {
        placeNameTask?.cancel()
        segmentPlaceNames = [:]

        let routeID = route.id
        let changePoints = route.weatherChangePoints
        placeNameTask = Task { [weak self] in
            let names = await GeocodingHelper.shared.resolvePlaceNames(for: changePoints)
            guard !Task.isCancelled,
                  let self,
                  self.currentRoute?.id == routeID else { return }
            self.segmentPlaceNames = names
        }
    }

    // MARK: - Maps URL Builders
    /// Builds the Apple Maps URL string with waypoints for the current route.
    /// Falls back to the last calculated route when offline.
    /// The View layer is responsible for opening the URL via UIApplication.
    public func appleMapsURLString() -> String? {
        guard mapsNavigationRoute != nil,
              let origin = originCoordinate,
              let destination = destinationCoordinate else { return nil }

        var urlString = "maps://?saddr=\(origin.latitude),\(origin.longitude)"
        for stop in selectedMapsWaypoints {
            urlString += "&daddr=\(stop.coordinate.latitude),\(stop.coordinate.longitude)"
        }
        urlString += "&daddr=\(destination.latitude),\(destination.longitude)"
        if avoidTollRoads { urlString += "&no_tolls=true" }
        return urlString
    }

    public func appleMapsWebURLString() -> String? {
        guard mapsNavigationRoute != nil,
              let origin = originCoordinate,
              let destination = destinationCoordinate else { return nil }
        var webString = "https://maps.apple.com/?saddr=\(origin.latitude),\(origin.longitude)"
        for stop in selectedMapsWaypoints {
            webString += "&daddr=\(stop.coordinate.latitude),\(stop.coordinate.longitude)"
        }
        webString += "&daddr=\(destination.latitude),\(destination.longitude)"
        if avoidTollRoads { webString += "&dirflg=d" }
        return webString
    }

    /// Builds the Google Maps URL string with waypoints for the current route.
    /// Falls back to the last calculated route when offline.
    public func googleMapsURLString() -> String? {
        guard mapsNavigationRoute != nil,
              let origin = originCoordinate,
              let destination = destinationCoordinate else { return nil }

        var urlString = "comgooglemaps://?saddr=\(origin.latitude),\(origin.longitude)"
        for stop in selectedMapsWaypoints {
            urlString += "&daddr=\(stop.coordinate.latitude),\(stop.coordinate.longitude)"
        }
        urlString += "&daddr=\(destination.latitude),\(destination.longitude)&directionsmode=driving"
        if avoidTollRoads { urlString += "&avoid=tolls" }
        return urlString
    }

    /// Builds the Google Maps web URL string with waypoints for the current route.
    /// Falls back to the last calculated route when offline.
    public func googleMapsWebURLString() -> String? {
        guard mapsNavigationRoute != nil,
              let origin = originCoordinate,
              let destination = destinationCoordinate else { return nil }
        var webString = "https://www.google.com/maps/dir/?api=1&origin=\(origin.latitude),\(origin.longitude)"
        if !selectedMapsWaypoints.isEmpty {
            let waypointsStr = selectedMapsWaypoints.map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }.joined(separator: "%7C")
            webString += "&waypoints=\(waypointsStr)"
        }
        webString += "&destination=\(destination.latitude),\(destination.longitude)&travelmode=driving"
        if avoidTollRoads { webString += "&avoid=tolls" }
        return webString
    }

    public func dismissError() { state = .idle }

    // MARK: - Auto-Refresh Timer

    /// Starts a periodic timer that recalculates the route every 3 minutes
    /// to account for traffic changes. Stops if the route is reset.
    private func startAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3 * 60 * 1_000_000_000) // 3 min
                guard let self = self, !Task.isCancelled else { break }
                guard self.currentRoute != nil, self.isOnline else { continue }
                AppLogger.wizPath.info("Auto-refreshing route for traffic...")
                self.isAutoRefreshing = true
                await self.calculateRoute()
            }
        }
    }

    // MARK: - Route Status for HUD

    private func updateRouteStatus(for route: WizPathRoute) {
        let status = computeRouteStatus(for: route)
        routeStatusForHUD = status
        WizPathHUDStatus.shared.currentStatus = status
    }

    private func computeRouteStatus(for route: WizPathRoute) -> RouteStatus {
        let dest = destinationName.isEmpty ? WizPathKitL10n.text("wizpath_destination") : destinationName
        let eta = formattedDuration(route.totalDuration)
        switch route.overallRisk {
        case .good: return .optimal(destination: dest, eta: eta)
        case .caution:
            let hazard = climateAnalysis?.primaryAlert?.title ?? WizPathKitL10n.text("wizpath_weather_hazard")
            return .warning(destination: dest, hazard: hazard, eta: eta)
        case .severe:
            let hazard = climateAnalysis?.primaryAlert?.title ?? WizPathKitL10n.text("wizpath_severe_hazard")
            return .critical(destination: dest, hazard: hazard)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 { return WizPathKitL10n.formatted("format_duration_hours_minutes", h, m) }
        return WizPathKitL10n.formatted("format_duration_minutes_only", m)
    }
}
