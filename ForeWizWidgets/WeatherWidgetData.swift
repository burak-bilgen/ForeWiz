import Foundation
import CryptoKit

/// Lightweight, codable model that the widget reads from UserDefaults (app group)
/// to display forecast information. The main app saves a matching JSON blob.
/// The stored data is encrypted with AES-GCM to prevent plaintext weather/location
/// data from being readable by other apps in the same app group.
struct WeatherWidgetData: Codable, Equatable, Sendable {
    let locationName: String
    let currentTemperature: Double
    let currentConditionSymbol: String
    let currentConditionDescription: String
    let outdoorScore: Int
    let dailyForecasts: [WidgetDailyForecast]
    let lastUpdated: Date
    let attributionName: String
    let languageCode: String

    static let appGroupSuiteName = "group.forewiz"
    static let userDefaultsKey = "com.forewiz.widget.weatherData"

    // MARK: - Result Type

    enum LoadResult: Equatable, Sendable {
        /// Data was loaded successfully.
        case success(WeatherWidgetData)
        /// The shared UserDefaults suite is unavailable (app group issue).
        case noSuite
        /// No data has been saved yet (first launch / app never ran).
        case noData
        /// Stored data is corrupted or from an older version.
        case corrupted(String)
        /// Stored data is stale (older than the given threshold in seconds).
        case stale(WeatherWidgetData, ageSeconds: TimeInterval)

        var isStale: Bool {
            if case .stale = self { return true }
            return false
        }

        var data: WeatherWidgetData? {
            switch self {
            case .success(let d), .stale(let d, _):
                return d
            case .noSuite, .noData, .corrupted:
                return nil
            }
        }
    }

    /// Freshness threshold: data older than this is considered stale.
    private static let staleThreshold: TimeInterval = 3600 * 2 // 2 hours

    /// Loads the latest cached widget data from shared UserDefaults with detailed error info.
    static func loadDetailed() -> LoadResult {
        guard let defaults = UserDefaults(suiteName: Self.appGroupSuiteName) else {
            return .noSuite
        }

        guard let encrypted = defaults.data(forKey: Self.userDefaultsKey) else {
            return .noData
        }

        let decrypted: Data
        do {
            decrypted = try Self.decryptWidgetData(encrypted)
        } catch {
            return .corrupted("Decryption failed: \(error.localizedDescription)")
        }

        do {
            let decoded = try JSONDecoder().decode(Self.self, from: decrypted)
            let age = -decoded.lastUpdated.timeIntervalSinceNow
            if age > staleThreshold {
                return .stale(decoded, ageSeconds: age)
            }
            return .success(decoded)
        } catch {
            return .corrupted(error.localizedDescription)
        }
    }

    /// Simple load that returns nil on any failure (for backward compat / quick checks).
    static func load() -> WeatherWidgetData? {
        loadDetailed().data
    }

    // MARK: - Data Decryption

    /// Decrypts widget data with AES-GCM.
    /// Tries the shared-container key first (randomly generated, more secure).
    /// Falls back to the deterministic key derived from the app group identifier.
    private static func decryptWidgetData(_ data: Data) throws -> Data {
        let key = loadEncryptionKey() ?? deterministicKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Loads the encryption key from the shared app group container.
    /// Returns nil if the key file doesn't exist (first launch or after reset).
    private static func loadEncryptionKey() -> SymmetricKey? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupSuiteName)?
            .appendingPathComponent(".widget-encryption-key-v1"),
              let keyData = try? Data(contentsOf: url),
              keyData.count == 32 else { return nil }
        return SymmetricKey(data: keyData)
    }

    /// Deterministic fallback key derived from the app group identifier.
    /// Matches the main app's fallback for backward compatibility.
    private static func deterministicKey() -> SymmetricKey {
        let material = "com.forewiz.widget.encryption.v1.\(appGroupSuiteName)"
        return SymmetricKey(data: SHA256.hash(data: Data(material.utf8)))
    }
}

struct WidgetDailyForecast: Codable, Equatable, Sendable, Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }

    let date: Date
    let dayName: String
    let highTemp: Double
    let lowTemp: Double
    let conditionSymbol: String
    let outdoorScore: Int
    let isToday: Bool
    let precipitationChance: Double
}
