import Foundation
import CoreLocation
import Combine
import OSLog

// MARK: - WizPath View State

enum WizPathViewState: Equatable {
    case idle
    case calculating
    case routeReady(WizPathRoute)
    case error(String)

    static func == (lhs: WizPathViewState, rhs: WizPathViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.calculating, .calculating):
            return true
        case (.routeReady(let l), .routeReady(let r)):
            return l.id == r.id
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    var isCalculating: Bool {
        if case .calculating = self { return true }
        return false
    }
    var route: WizPathRoute? {
        if case .routeReady(let r) = self { return r }
        return nil
    }
    var errorMessage: String? {
        if case .error(let m) = self { return m }
        return nil
    }
}

// MARK: - WizPath ViewModel

@MainActor
final class WizPathViewModel: ObservableObject {
    // MARK: - Dependencies
    private let wizPathService: WizPathService
    private let locationService: LocationService
    private let climateService = WizPathClimateService.shared
    private let sentinelService = WizPathSentinelService.shared

    // MARK: - Published State
    @Published var state: WizPathViewState = .idle
    @Published var travelMode: TravelMode = .car
    @Published var departureTime: Date = Date()
    @Published var destinationName: String = ""
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var originCoordinate: CLLocationCoordinate2D?
    @Published var originName: String = L10n.text("wizpath_current_location")
    @Published var recentDestinations: [RecentDestination] = []
    @Published var isShowingRoute = true
    @Published var showJourneyHUD = false
    @Published var climateAnalysis: ClimateAnalysis?
    @Published var routeStatusForHUD: RouteStatus = .noRoute
    @Published var sentinelAlerts: [SentinelAlert] = []

    // MARK: - Internal State
    private var lastCalculatedRoute: WizPathRoute?

    // MARK: - Computed
    var canCalculate: Bool {
        destinationCoordinate != nil && !state.isCalculating
    }

    var currentRoute: WizPathRoute? { state.route }
    var isCalculating: Bool { state.isCalculating }
    var errorMessage: String? { state.errorMessage }
    var routeSegments: [WizPathSegment] { currentRoute?.segments ?? [] }
    var weatherChangePoints: [WizPathSegment] { currentRoute?.weatherChangePoints ?? [] }
    var overallRisk: RouteRisk { currentRoute?.overallRisk ?? .good }

    // MARK: - Init
    init(
        wizPathService: WizPathService = .shared,
        locationService: LocationService? = nil
    ) {
        self.wizPathService = wizPathService
        self.locationService = locationService ?? DependencyContainer.shared?.locationService ?? {
            let ls = LocationService()
            ls.requestPermission()
            return ls
        }()
        loadCurrentLocation()
        loadRecentDestinations()
    }

    // MARK: - Location

    func loadCurrentLocation() {
        Task {
            do {
                let locationCoord = try await wizPathService.getCurrentLocation()
                originCoordinate = CLLocationCoordinate2D(
                    latitude: locationCoord.latitude,
                    longitude: locationCoord.longitude
                )
                AppLogger.wizPath.info("Location loaded: \(locationCoord.latitude), \(locationCoord.longitude)")
            } catch {
                AppLogger.wizPath.error("Location error: \(error.localizedDescription)")
                // Fallback to a default location
                originCoordinate = CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784)
                originName = L10n.text("wizpath_fallback_location")
            }
        }
    }

    func setDestination(coordinate: CLLocationCoordinate2D, name: String) {
        destinationCoordinate = coordinate
        destinationName = name
        state = .idle
        // Save to recents
        wizPathService.saveRecentDestination(name: name, coordinate: coordinate)
        loadRecentDestinations()
        // Auto-calculate
        Task { await calculateRoute() }
    }

    // MARK: - Recent Destinations

    func loadRecentDestinations() {
        recentDestinations = wizPathService.loadRecentDestinations()
    }

    func selectRecentDestination(_ recent: RecentDestination) {
        setDestination(coordinate: recent.coordinate, name: recent.name)
    }

    // MARK: - Route Calculation

    func calculateRoute() async {
        guard let origin = originCoordinate,
              let destination = destinationCoordinate else {
            state = .error(L10n.text("wizpath_error_no_destination"))
            return
        }

        state = .calculating
        HapticEngine.shared.medium()

        do {
            let route = try await wizPathService.calculateRoute(
                origin: origin,
                destination: destination,
                mode: travelMode,
                departureTime: departureTime
            )

            // Run climate analysis
            climateAnalysis = climateService.analyzeRouteClimate(route, travelMode: travelMode)

            // Check for sentinel alerts if we have a previous route
            if let previousRoute = lastCalculatedRoute {
                let routeConditions = route.segments.compactMap { $0.weather?.condition }
                let worstCondition = routeConditions.max(by: { $0.severity.rawValue < $1.severity.rawValue })
                let primaryHazard: WeatherHazardType? = {
                    switch worstCondition {
                    case .thunderstorm: return .severeStorm
                    case .heavyRain: return .flooding
                    case .snow, .sleet:
                        let avgTemp = route.segments.compactMap { $0.weather?.temperature }.reduce(0, +) / max(1, route.segments.count)
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

            // Update route status for HUD
            updateRouteStatus(for: route)

            state = .routeReady(route)
            showJourneyHUD = true
            HapticEngine.shared.success()
            AppLogger.wizPath.info("Route calculated: \(route.totalDuration)s, risk: \(route.overallRisk.rawValue)")
        } catch let error as WizPathError {
            state = .error(error.localizedDescription)
            HapticEngine.shared.warning()
        } catch {
            AppLogger.wizPath.error("Route calculation failed: \(error.localizedDescription)")
            state = .error(L10n.text("wizpath_error_route_failed"))
            HapticEngine.shared.error()
        }
    }

    // MARK: - Actions

    func switchTravelMode(to mode: TravelMode) {
        travelMode = mode
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil {
            Task { await calculateRoute() }
        }
    }

    func updateDepartureTime(_ date: Date) {
        departureTime = date
        HapticEngine.shared.selectionChanged()
        if currentRoute != nil {
            Task { await calculateRoute() }
        }
    }

    func refreshRoute() {
        HapticEngine.shared.weatherRefresh()
        if currentRoute != nil {
            Task { await calculateRoute() }
        }
    }

    func reset() {
        state = .idle
        destinationCoordinate = nil
        destinationName = ""
        showJourneyHUD = false
        HapticEngine.shared.light()
    }

    func dismissError() {
        state = .idle
    }

    // MARK: - Route Status for HUD

    private func updateRouteStatus(for route: WizPathRoute) {
        let status = computeRouteStatus(for: route)
        routeStatusForHUD = status
        WizPathHUDStatus.shared.currentStatus = status
    }

    private func computeRouteStatus(for route: WizPathRoute) -> RouteStatus {
        let dest = destinationName.isEmpty ? L10n.text("wizpath_destination") : destinationName
        let eta = formattedDuration(route.totalDuration)

        switch route.overallRisk {
        case .good:
            return .optimal(destination: dest, eta: eta)
        case .caution:
            let hazard = climateAnalysis?.primaryAlert?.title ?? L10n.text("wizpath_weather_hazard")
            return .warning(destination: dest, hazard: hazard, eta: eta)
        case .severe:
            let hazard = climateAnalysis?.primaryAlert?.title ?? L10n.text("wizpath_severe_hazard")
            return .critical(destination: dest, hazard: hazard)
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let h = Int(duration) / 3600
        let m = (Int(duration) % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}
