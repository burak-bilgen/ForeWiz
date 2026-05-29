import Foundation
import CoreLocation
import MapKit

// ⚠️ SIMULATED DATA — Gerçek yükseklik verisi kullanılmamaktadır.
// Bu servis, koordinatlardan türetilmiş sinüs-dalga tabanlı bir algoritma ile
// tutarlı (deterministik) ama gerçek olmayan yükseklik profili üretir.
// Gerçek dünya verisi için Apple'ın MKTerrain veya OpenElevation API
// entegrasyonu yapılması önerilir.

// MARK: - Elevation Service Protocol

/// Protocol for elevation data providers.
/// Allows swapping between simulated (default) and real API implementations.
public protocol ElevationServiceProtocol: AnyObject, Sendable {
    func fetchElevationProfile(for route: WizPathRoute) async throws -> ElevationProfile
}

// MARK: - Elevation Configuration

public enum ElevationProvider: String, Sendable {
    /// Sine-wave simulated data (always available, no network)
    case simulated
    /// Open Elevation API (free, no API key needed, requires network)
    case openElevationAPI
    /// Apple MKTerrain (iOS 17+, requires MapKit entitlement)
    case appleTerrain
}

/// Global configuration for which elevation provider to use.
/// Set before calling fetchElevationProfile to switch implementations.
public enum ElevationConfig {
    nonisolated(unsafe) public static var activeProvider: ElevationProvider = .simulated
    /// Whether to auto-fallback to simulated when the real API fails
    nonisolated(unsafe) public static var autoFallback: Bool = true
}

// MARK: - Elevation Provider Registry

public enum ElevationProviderFactory {
    /// Returns the provider matching the current configuration.
    /// If autoFallback is enabled and the selected provider fails,
    /// callers should fall back to SimulatedElevationService.
    public static func makeProvider() -> ElevationServiceProtocol {
        switch ElevationConfig.activeProvider {
        case .simulated:
            return SimulatedElevationService.shared
        case .openElevationAPI:
            return OpenElevationService.shared
        case .appleTerrain:
            return SimulatedElevationService.shared // Fallback — MKTerrain requires iOS 17+ entitlement
        }
    }

    /// The current provider, for convenience
    public static var current: ElevationServiceProtocol {
        makeProvider()
    }
}


public struct ElevationProfile: Sendable {
    public let points: [ElevationPoint]
    public let totalClimbMeters: Double
    public let totalDescentMeters: Double
    public let maxGradientPercent: Double
    public let terrainType: TerrainType
}

public struct ElevationPoint: Sendable {
    public let segmentIndex: Int
    public let coordinate: CLLocationCoordinate2D
    public let elevationMeters: Double
    public let gradientPercent: Double // positive is uphill, negative is downhill
}

public enum TerrainType: String, Sendable {
    case flat          // < 50m climb per 10km
    case rolling       // 50-200m climb per 10km
    case hilly         // 200-500m climb per 10km
    case mountainous   // > 500m climb per 10km
    
    public var localizedTitle: String {
        switch self {
        case .flat: return WizPathKitL10n.text("terrain_flat")
        case .rolling: return WizPathKitL10n.text("terrain_rolling")
        case .hilly: return WizPathKitL10n.text("terrain_hilly")
        case .mountainous: return WizPathKitL10n.text("terrain_mountainous")
        }
    }
}

/// ⚠️ SIMULATED DATA
///
/// `SimulatedElevationService` generates deterministic sine-wave based elevation
/// profiles from route coordinates. Used as a fallback when real APIs are unavailable.
public final class SimulatedElevationService: ElevationServiceProtocol, Sendable {
    public static let shared = SimulatedElevationService()
    private init() {}

    /// ⚠️ Simule edilmiş yükseklik profili döndürür.
    public func fetchElevationProfile(for route: WizPathRoute) async throws -> ElevationProfile {
        var points: [ElevationPoint] = []
        var totalClimb = 0.0
        var totalDescent = 0.0
        var maxGradient = 0.0

        let numSegments = route.segments.count
        guard numSegments > 1 else {
            return ElevationProfile(points: [], totalClimbMeters: 0, totalDescentMeters: 0, maxGradientPercent: 0, terrainType: .flat)
        }

        let startSeed = abs(route.origin.latitude + route.origin.longitude)
        let endSeed = abs(route.destination.latitude + route.destination.longitude)

        var previousElevation = 150.0 + (startSeed.truncatingRemainder(dividingBy: 1) * 300.0)

        for i in 0..<numSegments {
            let progress = Double(i) / Double(numSegments - 1)
            let coord = route.segments[i].coordinate

            let distanceProgress = progress * Double(numSegments) * 0.15
            let primaryHill = sin(distanceProgress * 2.0) * 120.0
            let secondaryRidge = cos(distanceProgress * 5.3) * 35.0
            let minorTexture = sin(distanceProgress * 12.0) * 8.0

            let destBaseElevation = 150.0 + (endSeed.truncatingRemainder(dividingBy: 1) * 300.0)
            let trend = progress * (destBaseElevation - previousElevation)

            let currentElevation = max(10.0, previousElevation + primaryHill + secondaryRidge + minorTexture + trend)

            var gradient = 0.0
            if i > 0 {
                let prevPointCoord = route.segments[i-1].coordinate
                let prevLocation = CLLocation(latitude: prevPointCoord.latitude, longitude: prevPointCoord.longitude)
                let currLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let distanceRun = currLocation.distance(from: prevLocation)

                if distanceRun > 0 {
                    let rise = currentElevation - points[i-1].elevationMeters
                    gradient = (rise / distanceRun) * 100.0

                    if rise > 0 { totalClimb += rise }
                    else { totalDescent += abs(rise) }

                    maxGradient = max(maxGradient, abs(gradient))
                }
            }

            points.append(ElevationPoint(
                segmentIndex: i, coordinate: coord,
                elevationMeters: currentElevation, gradientPercent: gradient
            ))
        }

        let totalDistanceKm = route.totalDistance / 1000.0
        let climbPer10k = totalDistanceKm > 0 ? (totalClimb / totalDistanceKm) * 10.0 : 0.0

        let terrainType: TerrainType
        if climbPer10k < 50.0 { terrainType = .flat }
        else if climbPer10k < 200.0 { terrainType = .rolling }
        else if climbPer10k < 500.0 { terrainType = .hilly }
        else { terrainType = .mountainous }

        return ElevationProfile(
            points: points, totalClimbMeters: totalClimb,
            totalDescentMeters: totalDescent, maxGradientPercent: maxGradient,
            terrainType: terrainType
        )
    }
}

// MARK: - Open Elevation API Integration

/// Real elevation data provider using the free Open Elevation API.
/// No API key required. Rate-limited: ~1 request/second recommended.
/// API: https://api.open-elevation.com/api/v1/lookup?locations=lat,lng|lat,lng
public final class OpenElevationService: ElevationServiceProtocol, Sendable {
    public static let shared = OpenElevationService()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    private struct OpenElevationRequest: Codable {
        let locations: [OpenElevationLocation]
    }

    private struct OpenElevationLocation: Codable {
        let latitude: Double
        let longitude: Double
    }

    private struct OpenElevationResponse: Codable {
        let results: [OpenElevationResult]
    }

    private struct OpenElevationResult: Codable {
        let latitude: Double
        let longitude: Double
        let elevation: Double?
    }

    /// Fetches real elevation data from the Open Elevation API.
    /// Falls back to simulated data if the API is unreachable.
    public func fetchElevationProfile(for route: WizPathRoute) async throws -> ElevationProfile {
        let coordinates = route.segments.map { segment in
            OpenElevationLocation(latitude: segment.coordinate.latitude,
                                  longitude: segment.coordinate.longitude)
        }

        guard !coordinates.isEmpty else {
            return ElevationProfile(points: [], totalClimbMeters: 0, totalDescentMeters: 0,
                                    maxGradientPercent: 0, terrainType: .flat)
        }

        do {
            let elevations = try await fetchElevationBulk(coordinates: coordinates)
            return buildProfile(from: elevations, route: route)
        } catch {
            AppLogger.wizPath.warning("Open Elevation API failed: \(error.localizedDescription)")
            if ElevationConfig.autoFallback {
                AppLogger.wizPath.info("Falling back to simulated elevation data")
                return try await SimulatedElevationService.shared.fetchElevationProfile(for: route)
            }
            throw error
        }
    }

    /// Fetches elevation data for multiple coordinates in a single API call.
    /// The API accepts up to ~100 locations per request.
    private func fetchElevationBulk(coordinates: [OpenElevationLocation]) async throws -> [OpenElevationResult] {
        let locationsStr = coordinates.map { "\($0.latitude),\($0.longitude)" }.joined(separator: "|")
        guard let encoded = locationsStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw WizPathError.weatherAPIFailed
        }

        let urlString = "https://api.open-elevation.com/api/v1/lookup?locations=\(encoded)"
        guard let url = URL(string: urlString) else {
            throw WizPathError.weatherAPIFailed
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WizPathError.weatherAPIFailed
        }

        let apiResponse = try decoder.decode(OpenElevationResponse.self, from: data)
        return apiResponse.results
    }

    /// Builds an ElevationProfile from API results, computing climb/descent/gradient.
    private func buildProfile(from results: [OpenElevationResult], route: WizPathRoute) -> ElevationProfile {
        var points: [ElevationPoint] = []
        var totalClimb = 0.0
        var totalDescent = 0.0
        var maxGradient = 0.0

        for i in 0..<results.count {
            let result = results[i]
            let elevation = result.elevation ?? 0.0

            var gradient = 0.0
            if i > 0 {
                let prevPoint = points[i-1]
                let prevLocation = CLLocation(latitude: results[i-1].latitude,
                                              longitude: results[i-1].longitude)
                let currLocation = CLLocation(latitude: result.latitude,
                                              longitude: result.longitude)
                let distanceRun = currLocation.distance(from: prevLocation)

                if distanceRun > 0 {
                    let rise = elevation - prevPoint.elevationMeters
                    gradient = (rise / distanceRun) * 100.0

                    if rise > 0 { totalClimb += rise }
                    else { totalDescent += abs(rise) }

                    maxGradient = max(maxGradient, abs(gradient))
                }
            }

            let coord = CLLocationCoordinate2D(latitude: result.latitude,
                                               longitude: result.longitude)
            points.append(ElevationPoint(
                segmentIndex: i, coordinate: coord,
                elevationMeters: elevation, gradientPercent: gradient
            ))
        }

        let totalDistanceKm = route.totalDistance / 1000.0
        let climbPer10k = totalDistanceKm > 0 ? (totalClimb / totalDistanceKm) * 10.0 : 0.0

        let terrainType: TerrainType
        if climbPer10k < 50.0 { terrainType = .flat }
        else if climbPer10k < 200.0 { terrainType = .rolling }
        else if climbPer10k < 500.0 { terrainType = .hilly }
        else { terrainType = .mountainous }

        return ElevationProfile(
            points: points, totalClimbMeters: totalClimb,
            totalDescentMeters: totalDescent, maxGradientPercent: maxGradient,
            terrainType: terrainType
        )
    }
}

// MARK: - Legacy ElevationService (backward-compatible alias)

/// ⚠️ Legacy alias. Use `ElevationProviderFactory.current` or configure `ElevationConfig.activeProvider`
/// to switch between simulated and real elevation data.
public final class ElevationService: ElevationServiceProtocol, Sendable {
    public static let shared = ElevationService()
    private init() {}

    /// Delegates to the currently configured elevation provider.
    public func fetchElevationProfile(for route: WizPathRoute) async throws -> ElevationProfile {
        try await ElevationProviderFactory.current.fetchElevationProfile(for: route)
    }
}
