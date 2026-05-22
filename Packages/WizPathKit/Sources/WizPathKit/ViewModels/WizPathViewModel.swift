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

    // MARK: - Internal State
    private var lastCalculatedRoute: WizPathRoute?
    public var didLoadInitialLocation = false
    // Auto-refresh timer for traffic updates
    private var refreshTimer: Task<Void, Never>?
    private var isAutoRefreshing = false
    public var selectedWeatherSegment: WizPathSegment?
    public var showWeatherDetail = false
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

    public func calculateRoute() async {
        guard isOnline else {
            if isAutoRefreshing, let lastRoute = lastCalculatedRoute {
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
            let route = try await wizPathService.calculateRoute(origin: origin, destination: destination, mode: travelMode, departureTime: departureTime)
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
            updateRouteStatus(for: route)
            await analyzeBestDepartureTime(route: route)
            state = .routeReady(route)
            showJourneyHUD = true
            if !isAutoRefreshing { HapticEngine.shared.success() }
            startAutoRefresh()
            
            // Resolve place names for weather change points (async, non-blocking)
            Task {
                let changePoints = route.weatherChangePoints
                let names = await GeocodingHelper.shared.resolvePlaceNames(for: changePoints)
                segmentPlaceNames = names
            }
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
        state = .idle
        destinationCoordinate = nil
        destinationName = ""
        showJourneyHUD = false
        showWeatherDetail = false
        selectedWeatherSegment = nil
        HapticEngine.shared.light()
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
