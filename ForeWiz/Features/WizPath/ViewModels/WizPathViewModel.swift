import Foundation
import CoreLocation
import Combine
import OSLog

// MARK: - WizPath View Model
@MainActor
final class WizPathViewModel: ObservableObject {
    // MARK: - Dependencies
    private let wizPathService: WizPathService
    private let locationService: LocationService
    
    // MARK: - Published State
    @Published var currentRoute: WizPathRoute?
    @Published var isCalculating = false
    @Published var travelMode: TravelMode = .car
    @Published var departureTime: Date = Date()
    @Published var destinationName: String = ""
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var originCoordinate: CLLocationCoordinate2D?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Computed Properties
    var canCalculate: Bool {
        destinationCoordinate != nil && !isCalculating
    }
    
    // MARK: - Initialization
    init(
        wizPathService: WizPathService = .shared,
        locationService: LocationService = .shared
    ) {
        self.wizPathService = wizPathService
        self.locationService = locationService
        
        // Get current location on init
        Task {
            await fetchCurrentLocation()
        }
    }
    
    // MARK: - Location Management
    
    private func fetchCurrentLocation() async {
        do {
            let location = try await locationService.requestCurrentLocation()
            originCoordinate = location.coordinate
        } catch {
            AppLogger.location.error("Failed to get current location: \(error)")
        }
    }
    
    func setDestination(_ location: CLLocation) {
        destinationCoordinate = location.coordinate
        destinationName = location.name ?? L10n.text("wizpath_unknown_location")
    }
    
    func setDestination(coordinate: CLLocationCoordinate2D, name: String) {
        destinationCoordinate = coordinate
        destinationName = name
    }
    
    // MARK: - Route Calculation
    
    func calculateRoute() async {
        guard let origin = originCoordinate,
              let destination = destinationCoordinate else {
            showError(message: L10n.text("wizpath_error_no_destination"))
            return
        }
        
        isCalculating = true
        defer { isCalculating = false }
        
        do {
            let route = try await wizPathService.calculateRoute(
                origin: origin,
                destination: destination,
                mode: travelMode,
                departureTime: departureTime
            )
            
            self.currentRoute = route
            
        } catch let error as WizPathError {
            showError(message: error.localizedDescription ?? L10n.text("wizpath_error_unknown"))
        } catch {
            showError(message: L10n.text("wizpath_error_unknown"))
        }
    }
    
    // MARK: - Route Updates
    
    func recalculateWithTraffic() async {
        // Only recalculate if we have a current route
        guard currentRoute != nil else { return }
        
        // Update departure time to now
        departureTime = Date()
        
        // Recalculate
        await calculateRoute()
    }
    
    func switchTravelMode(to mode: TravelMode) async {
        travelMode = mode
        
        // Recalculate if we have a route
        if currentRoute != nil {
            await calculateRoute()
        }
    }
    
    func updateDepartureTime(_ date: Date) async {
        departureTime = date
        
        // Recalculate if we have a route (weather may change)
        if currentRoute != nil {
            await calculateRoute()
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Route Segments
    
    var routeSegments: [WizPathSegment] {
        currentRoute?.segments ?? []
    }
    
    var weatherChangePoints: [WizPathSegment] {
        currentRoute?.weatherChangePoints ?? []
    }
    
    var overallRisk: RouteRisk {
        currentRoute?.overallRisk ?? .good
    }
    
    // MARK: - Cleanup
    
    func reset() {
        currentRoute = nil
        destinationCoordinate = nil
        destinationName = ""
        errorMessage = ""
        showError = false
    }
}

// MARK: - Location Service Extension
extension LocationService {
    static let shared = LocationService()
    
    func requestCurrentLocation() async throws -> CLLocation {
        // Implementation would use CoreLocation
        // For architecture, returning a mock
        return CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
    }
}

// MARK: - CLLocation Extension
extension CLLocation {
    var name: String? {
        // Would use CLGeocoder in production
        return nil
    }
}
