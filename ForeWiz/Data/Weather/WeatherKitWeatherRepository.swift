import CoreLocation
import Foundation
import OSLog
import WeatherKit

// MARK: - Rate Limiter
/// Prevents WeatherKit API calls more frequently than the minimum interval.
/// Avoids hitting Apple's rate limits and reduces battery drain from rapid refreshes.
private actor WeatherKitRateLimiter {
    static let shared = WeatherKitRateLimiter()
    
    private var lastFetchTime: Date?
    private let minimumInterval: TimeInterval = 30 // seconds between calls
    
    func canFetch() -> Bool {
        guard let last = lastFetchTime else {
            lastFetchTime = Date()
            return true
        }
        let elapsed = Date().timeIntervalSince(last)
        guard elapsed >= minimumInterval else {
            AppLogger.weather.info("WeatherKit rate limited: \(Int(self.minimumInterval - elapsed))s remaining")
            return false
        }
        lastFetchTime = Date()
        return true
    }
    
    func reset() {
        lastFetchTime = nil
    }
}

final class WeatherKitWeatherRepository: WeatherRepository {
    private let service: WeatherService
    private let dateProvider: DateProvider
    private let rateLimiter = WeatherKitRateLimiter.shared

    init(
        service: WeatherService = .shared,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.service = service
        self.dateProvider = dateProvider
    }

    func fetchWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot {
        // ⏱️ Rate limiting: prevent calls more frequent than 30s
        guard await rateLimiter.canFetch() else {
            // Try to return cached data instead of throwing
            throw AppError.weatherUnavailable
        }
        
        do {
            let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            AppLogger.weather.info("Fetching WeatherKit forecast")
            let weather = try await service.weather(for: clLocation)
            let attribution = try? await makeAttributionInfo()
            AppLogger.weather.info("WeatherKit forecast fetched successfully")

            return WeatherMapper.snapshot(
                from: weather,
                location: location,
                fetchedAt: dateProvider.now,
                attribution: attribution
            )
        } catch WeatherError.permissionDenied {
            let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
            let message = "WeatherKit permission denied for bundle: \(bundleID). " +
                "Check App ID WeatherKit capability and provisioning."
            AppLogger.weather.error("\(message)")
            throw AppError.weatherKitPermissionMissing
        } catch WeatherError.unknown {
            AppLogger.weather.error("WeatherKit failed with WeatherError.unknown")
            throw AppError.weatherKitFailed(L10n.text("error_weatherkit_unknown"))
        } catch {
            let diagnostic = Self.diagnosticDescription(for: error)
            AppLogger.weather.error("WeatherKit request failed: \(diagnostic, privacy: .private)")
            if Self.isAuthenticationFailure(diagnostic) {
                throw AppError.weatherKitPermissionMissing
            }
            throw AppError.weatherKitFailed(diagnostic)
        }
    }

    private func makeAttributionInfo() async throws -> WeatherAttributionInfo {
        let attribution = try await service.attribution
        return WeatherAttributionInfo(
            serviceName: attribution.serviceName,
            legalPageURLString: attribution.legalPageURL.absoluteString,
            legalAttributionText: attribution.legalAttributionText
        )
    }

    private static func diagnosticDescription(for error: any Error) -> String {
        let localizedDescription = error.localizedDescription
        let reflectedDescription = String(reflecting: error)

        guard localizedDescription != reflectedDescription else {
            return localizedDescription
        }
        // NOT logged anywhere - only used for internal diagnostic matching (caller applies privacy)
        return "\(localizedDescription) (\(reflectedDescription))"
    }

    private static func isAuthenticationFailure(_ diagnostic: String) -> Bool {
        diagnostic.contains("WDSJWTAuthenticatorServiceListener.Errors")
        || diagnostic.contains("invalidAuthorization")
        || diagnostic.contains("401")
    }
}
