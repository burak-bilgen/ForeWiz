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
    let wizPathService: WizPathService
    let departureOptimizerService: DepartureOptimizerService?
    let climateService: WizPathClimateService
    let sentinelService: WizPathSentinelService
    let cyclingSafetyService: WizPathCyclingSafetyService
    let poiSearchService: POISearchService

    // MARK: - State
    public var state: WizPathViewState = .idle
    public var travelMode: TravelMode = .car
    public var departureTime: Date = {
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
    public var onRouteEnded: ((_ route: WizPathRoute, _ destinationName: String, _ travelMode: TravelMode) -> Void)?
    var hasEndedRoute = false
    public var smartStops: [SmartStop] = []
    public var isLoadingMapDetails = false
    // MARK: - Vehicle Type
    public var vehicleType: VehicleType {
        didSet {
            Foundation.UserDefaults.standard.set(vehicleType.rawValue, forKey: AppKeys.UserDefaults.wizPathVehicleType)
            HapticEngine.shared.selectionChanged()
            // Durakları vehicleType'a göre yenile
            if currentRoute != nil { Task { await recalculateStops() } }
        }
    }

    public var evChargers: [SmartStop] = []
    public var isLoadingEVChargers = false
    public var evChargerError: String?

    // MARK: - Route Comparison & Preferences
    public var routeCandidates: [ScoredRouteCandidate] = []
    public var selectedRouteIndex: Int = 0
    public var avoidTollRoads = false
    public var currentTrafficCongestion: TrafficCongestionLevel = .unknown
    public var hasTollRoads: Bool = false
    public var showRouteComparison = false
    public var mapExpanded = true
    public var showTrafficOnMap = false

    // MARK: - Waypoint Selection
    public var selectedWaypointIds: Set<UUID>? = nil

    // MARK: - Internal State
    /// fileprivate internal erişim — extension dosyaları erişebilir.
    var lastCalculatedRoute: WizPathRoute?

    /// VehicleType değişince durakları yeniden hesapla
    private func recalculateStops() async {
        guard let route = currentRoute else { return }
        refreshSmartStops(for: route)
        if vehicleType == .electric || vehicleType == .hybrid {
            refreshEVChargers(for: route)
        } else {
            evChargers = []
            isLoadingEVChargers = false
            evChargerError = nil
        }
    }
    var lastCalculatedRouteTimestamp: Date?
    let cacheExpirationInterval: TimeInterval = 1800 // 30 minutes
    public var didLoadInitialLocation = false
    private var refreshTimer: Task<Void, Never>?
    /// internal erişim — WizPathViewModel+EV.swift erişebilir.
    var smartStopsTask: Task<Void, Never>?
    private var placeNameTask: Task<Void, Never>?
    private var isAutoRefreshing = false
    public var selectedWeatherSegment: WizPathSegment?
    public var showWeatherDetail = false
    public var segmentPlaceNames: [UUID: String] = [:]

    /// Maximum time to wait for the full route calculation pipeline before timing out.
    /// MKDirections itself has a 30s timeout inside the service — this is a safety net
    /// for the entire pipeline (MKDirections + weather + toll detection + scoring).
    private static let routeCalculationTimeout: TimeInterval = 90.0

    // MARK: - Computed
    public var canCalculate: Bool { destinationCoordinate != nil && !state.isCalculating && isOnline }
    public var currentRoute: WizPathRoute? { state.route }
    public var isCalculating: Bool { state.isCalculating }
    public var errorMessage: String? { state.errorMessage }
    public var routeSegments: [WizPathSegment] { currentRoute?.segments ?? [] }
    public var weatherChangePoints: [WizPathSegment] { currentRoute?.weatherChangePoints ?? [] }
    public var overallRisk: RouteRisk { currentRoute?.overallRisk ?? .good }


    // MARK: - Init
    public init(
        wizPathService: WizPathService,
        departureOptimizerService: DepartureOptimizerService? = nil,
        climateService: WizPathClimateService = .shared,
        sentinelService: WizPathSentinelService = .shared,
        cyclingSafetyService: WizPathCyclingSafetyService = .shared,
        poiSearchService: POISearchService = .shared
    ) {
        // UserDefaults'tan kayıtlı araç tipini yükle, yoksa varsayılan petrol
        let saved = Foundation.UserDefaults.standard.string(forKey: AppKeys.UserDefaults.wizPathVehicleType)
        self.vehicleType = saved.flatMap(VehicleType.init(rawValue:)) ?? .default

        self.wizPathService = wizPathService
        self.departureOptimizerService = departureOptimizerService
        self.climateService = climateService
        self.sentinelService = sentinelService
        self.cyclingSafetyService = cyclingSafetyService
        self.poiSearchService = poiSearchService
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

    public func clearRecentDestinations() {
        recentDestinations = []
        Foundation.UserDefaults.standard.removeObject(forKey: AppKeys.UserDefaults.wizPathRecentDestinations)
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
        
        // Update climate analysis for this specific route candidate
        climateAnalysis = climateService.analyzeRouteClimate(candidate.route, travelMode: travelMode)
        
        // Update cycling safety for this specific route candidate
        if travelMode == .cycling {
            cyclingSafetyAnalysis = cyclingSafetyService.analyzeCyclingSafety(route: candidate.route)
            let winds = candidate.route.segments.compactMap { $0.weather?.windSpeed }
            let temps = candidate.route.segments.compactMap { $0.weather?.temperature }
            let precips = candidate.route.segments.compactMap { $0.weather?.precipitationChance }
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
        
        updateRouteStatus(for: candidate.route)
        showJourneyHUD = true
        HapticEngine.shared.selectionChanged()
        
        // Refresh smart stops for the new active candidate route
        refreshSmartStops(for: candidate.route)
        refreshEVChargers(for: candidate.route)
        
        // Run place names resolution and best departure time analysis asynchronously
        Task {
            await analyzeBestDepartureTime(route: candidate.route)
            resolvePlaceNames(for: candidate.route)
        }
        
        AppLogger.wizPath.info("Switched to route candidate #\(index): score=\(candidate.score)")
    }

    public func toggleAvoidTollRoads() {
        avoidTollRoads.toggle()
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func calculateRoute() async {
        guard isOnline else {
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
            // Run the route calculation with a timeout to prevent hangs
            // when MKDirections is slow or network is degraded
            let result = try await withThrowingTaskGroup(
                of: (best: WizPathRoute, candidates: [ScoredRouteCandidate]).self
            ) { group in
                // The actual route calculation
                group.addTask {
                    try await self.wizPathService.calculateRouteWithCandidates(
                        origin: origin,
                        destination: destination,
                        mode: self.travelMode,
                        departureTime: self.departureTime,
                        avoidTollRoads: self.avoidTollRoads
                    )
                }
                // Timeout guard — if this fires first, we cancel the calculation
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(Self.routeCalculationTimeout * 1_000_000_000))
                    throw WizPathError.timeout
                }
                // Take whichever completes first (route or timeout)
                let result = try await group.next()!
                // Cancel remaining tasks (the timeout or the calculation)
                group.cancelAll()
                return result
            }

            let route = result.best
            routeCandidates = result.candidates
            selectedRouteIndex = 0

            if let bestCandidate = result.candidates.first {
                currentTrafficCongestion = bestCandidate.trafficCongestion
                hasTollRoads = bestCandidate.hasTollRoads
            } else {
                currentTrafficCongestion = .unknown
                hasTollRoads = false
            }
            climateAnalysis = climateService.analyzeRouteClimate(route, travelMode: travelMode)

            if travelMode == .cycling {
                cyclingSafetyAnalysis = cyclingSafetyService.analyzeCyclingSafety(route: route)
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

            // EV features removed

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
                let weatherContext = WeatherContext(
                    primaryHazard: primaryHazard,
                    temperature: climateAnalysis?.maxTemperature,
                    conditions: routeConditions,
                    isExtreme: climateAnalysis?.isExtremeHeat ?? false
                )
                let decision = sentinelService.evaluateRouteChange(
                    originalRoute: previousRoute,
                    updatedRoute: route,
                    weatherContext: weatherContext
                )
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
            refreshSmartStops(for: route)
            refreshEVChargers(for: route)
            if !isAutoRefreshing { HapticEngine.shared.success() }
            startAutoRefresh()
            resolvePlaceNames(for: route)
            AppLogger.wizPath.info("Route calculated: \(route.totalDuration)s, risk: \(route.overallRisk.rawValue)")
        } catch let error as WizPathError {
            if case .timeout = error {
                AppLogger.wizPath.error("Route calculation timed out after \(Self.routeCalculationTimeout)s")
                if isAutoRefreshing, let lastRoute = lastCalculatedRoute {
                    state = .routeReady(lastRoute)
                } else {
                    state = .error(WizPathKitL10n.text("wizpath_error_timeout"))
                    HapticEngine.shared.warning()
                }
            } else {
                if isAutoRefreshing, let lastRoute = lastCalculatedRoute {
                    state = .routeReady(lastRoute)
                } else {
                    state = .error(error.localizedDescription)
                    HapticEngine.shared.warning()
                }
            }
        } catch {
            AppLogger.wizPath.error("Route calculation failed: \(error.localizedDescription)")
            if isAutoRefreshing, let lastRoute = lastCalculatedRoute {
                state = .routeReady(lastRoute)
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
        }
    }

    // MARK: - Actions

    public func switchTravelMode(to mode: TravelMode) {
        travelMode = mode
        if mode != .cycling {
            cyclingSafetyAnalysis = nil
            cyclingSafetyRecommendations = []
        }
        if mode != .car {
            evChargers = []
            isLoadingEVChargers = false
            evChargerError = nil
        }
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil { Task { await calculateRoute() } }
    }

    public func updateDepartureTime(_ date: Date) {
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
        if let route = lastCalculatedRoute, !hasEndedRoute {
            hasEndedRoute = true
            let name = destinationName
            let mode = travelMode
            onRouteEnded?(route, name, mode)
        }
        refreshTimer?.cancel()
        refreshTimer = nil
        smartStopsTask?.cancel()
        smartStopsTask = nil
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
        smartStops = []
        evChargers = []
        isLoadingEVChargers = false
        evChargerError = nil
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

    // MARK: - EV Mode, Charging Stations & Smart Stop Helpers
    // (Defined in WizPathViewModel+EV.swift)

    // MARK: - Maps URL Builders
    // (Defined in WizPathViewModel+Navigation.swift)

    // MARK: - Smart Stop Search

    func refreshSmartStops(for route: WizPathRoute) {
        isLoadingMapDetails = true
        smartStopsTask?.cancel()
        smartStops = []

        let categories: [POICategory]
        switch travelMode {
        case .car:
            // Araç tipine göre POI filtrele: EV → şarj, Benzinli → gaz, Hibrit → ikisi de
            categories = vehicleType.relevantCategories
        case .cycling, .walking:
            categories = [.restStop, .restaurant]
        }

        let routeID = route.id
        smartStopsTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isLoadingMapDetails = false }

            let foundStops = await self.poiSearchService.searchSmartStopsAlongRoute(
                route: route,
                categories: categories
            )

            guard !Task.isCancelled,
                  self.currentRoute?.id == routeID else { return }

            var enrichedStops: [SmartStop] = []
            for stop in foundStops {
                let arrivalSegment = self.closestSegment(for: stop.coordinate, in: route)
                let weatherAtArrival = arrivalSegment?.weather
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
                    etaArrival: arrivalSegment?.estimatedArrival ?? stop.etaArrival,
                    weatherAtArrival: weatherAtArrival,
                    safetyStatus: safetyStatus,
                    distanceFromRoute: stop.distanceFromRoute,
                    estimatedStopDuration: stop.estimatedStopDuration,
                    weatherRecommendation: recommendation
                )
                enrichedStops.append(enriched)
            }

            self.smartStops = enrichedStops
        }
    }

    // MARK: - EV Charger Search

    func refreshEVChargers(for route: WizPathRoute) {
        guard travelMode == .car, vehicleType == .electric || vehicleType == .hybrid else {
            evChargers = []
            isLoadingEVChargers = false
            evChargerError = nil
            return
        }

        isLoadingEVChargers = true
        evChargerError = nil
        evChargers = []

        let routeID = route.id
        Task { [weak self] in
            guard let self else { return }
            defer { self.isLoadingEVChargers = false }

            let foundStops = await self.poiSearchService.searchSmartStopsAlongRoute(
                route: route,
                categories: [.evCharger]
            )

            guard !Task.isCancelled,
                  self.currentRoute?.id == routeID else { return }

            var enrichedStops: [SmartStop] = []
            for stop in foundStops {
                let arrivalSegment = self.closestSegment(for: stop.coordinate, in: route)
                let weatherAtArrival = arrivalSegment?.weather
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
                    etaArrival: arrivalSegment?.estimatedArrival ?? stop.etaArrival,
                    weatherAtArrival: weatherAtArrival,
                    safetyStatus: safetyStatus,
                    distanceFromRoute: stop.distanceFromRoute,
                    estimatedStopDuration: stop.estimatedStopDuration,
                    weatherRecommendation: recommendation
                )
                enrichedStops.append(enriched)
            }

            self.evChargers = enrichedStops
        }
    }

    func closestSegment(for coordinate: CLLocationCoordinate2D, in route: WizPathRoute) -> WizPathSegment? {
        let stopLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return route.segments.min(by: {
            let locA = CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            let locB = CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude)
            return stopLocation.distance(from: locA) < stopLocation.distance(from: locB)
        })
    }

    func computeStopSafetyStatus(weather: SegmentWeather?) -> POISafetyStatus {
        guard let weather = weather else { return .safe }
        switch weather.severity {
        case .good: return .safe
        case .fair: return .safe
        case .caution: return .caution
        case .severe: return .unsafe
        }
    }

    func generateWeatherRecommendation(category: POICategory, weather: SegmentWeather?, mode: TravelMode) -> String? {
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

    // MARK: - Place Name Resolution

    func resolvePlaceNames(for route: WizPathRoute) {
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

    public func dismissError() { state = .idle }

    // MARK: - Auto-Refresh Timer

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
