import CoreLocation
import Foundation
import OSLog
import WeatherKit

final class WeatherKitWeatherRepository: WeatherRepository {
    private let service: WeatherService
    private let dateProvider: DateProvider

    init(
        service: WeatherService = .shared,
        dateProvider: DateProvider = SystemDateProvider()
    ) {
        self.service = service
        self.dateProvider = dateProvider
    }

    func fetchWeather(for location: LocationCoordinate) async throws -> WeatherSnapshot {
        do {
            let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            AppLogger.weather.info(
                "Fetching WeatherKit forecast for lat=\(location.latitude), lon=\(location.longitude)"
            )
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
            AppLogger.weather.error("WeatherKit request failed: \(diagnostic, privacy: .public)")
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

        return "\(localizedDescription) (\(reflectedDescription))"
    }

    private static func isAuthenticationFailure(_ diagnostic: String) -> Bool {
        diagnostic.contains("WDSJWTAuthenticatorServiceListener.Errors")
        || diagnostic.contains("invalidAuthorization")
        || diagnostic.contains("401")
    }
}
