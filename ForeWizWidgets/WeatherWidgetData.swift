import Foundation
import CryptoKit

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

    enum LoadResult: Equatable, Sendable {

        case success(WeatherWidgetData)

        case noSuite

        case noData

        case corrupted(String)

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

    private static let staleThreshold: TimeInterval = 3600 * 2

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

    static func load() -> WeatherWidgetData? {
        loadDetailed().data
    }

    private static func decryptWidgetData(_ data: Data) throws -> Data {
        let key = loadEncryptionKey() ?? deterministicKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }

    private static func loadEncryptionKey() -> SymmetricKey? {
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupSuiteName)?
            .appendingPathComponent(".widget-encryption-key-v1"),
              let keyData = try? Data(contentsOf: url),
              keyData.count == 32 else { return nil }
        return SymmetricKey(data: keyData)
    }

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
