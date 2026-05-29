import Foundation
import CoreLocation

// MARK: - Overpass Charger Info

/// Gerçek OSM verisinden çekilmiş şarj istasyonu bilgileri.
public struct OverpassChargerInfo: Sendable, Equatable {
    public let connectorTypes: [EVConnectorType]
    public let maxPowerKw: Double?
    public let stationCount: Int?
    public let operatorName: String?
    public let isFastCharger: Bool

    public init(connectorTypes: [EVConnectorType], maxPowerKw: Double? = nil,
                stationCount: Int? = nil, operatorName: String? = nil, isFastCharger: Bool = false) {
        self.connectorTypes = connectorTypes
        self.maxPowerKw = maxPowerKw
        self.stationCount = stationCount
        self.operatorName = operatorName
        self.isFastCharger = isFastCharger
    }
}

// MARK: - Overpass Charger Service

/// 🔌 Gerçek şarj istasyonu konnektör verisi için OpenStreetMap Overpass API entegrasyonu.
///
/// Apple Maps'in MKMapItem API'si konnektör tipi bilgisi vermez.
/// Bu servis, OSM veritabanındaki `amenity=charging_station` etiketlerine
/// ve `socket:*` tag'lerine bakarak gerçek konnektör tiplerini döndürür.
///
/// **Tamamen ücretsiz, API key gerektirmez.**
/// - API: `https://overpass-api.de/api/interpreter`
/// - Cache: 1 saat (OSM verisi sık değişmez)
///
/// **OSM Tag Referansı:**
/// - `amenity=charging_station` — şarj istasyonu
/// - `socket:type2=*` / `socket:type2_combo=*` — CCS
/// - `socket:chademo=*` — CHAdeMO
/// - `socket:tesla_supercharger=*` / `socket:nacs=*` — NACS (Tesla)
/// - `socket:type1=*` / `socket:type3=*` — Type 1 / Type 3
/// - `capacity:*` — kullanılabilir soket sayısı
/// - `maxpower=*` — maksimum şarj gücü (kW)
/// - `operator=*` — operatör adı
public final class OverpassChargerService: Sendable {
    public static let shared = OverpassChargerService()

    private let session: URLSession
    private let cache = ChargerOverpassCache()

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    /// Belirli bir koordinattaki şarj istasyonu bilgilerini döndürür.
    /// - Parameter coordinate: Sorgulanacak koordinat
    /// - Returns: OverpassChargerInfo veya nil (veri yoksa / hata varsa)
    public func fetchChargerInfo(at coordinate: CLLocationCoordinate2D) async -> OverpassChargerInfo? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"
        if let cached = await cache.retrieve(key: cacheKey) {
            return cached
        }

        let info = await queryOverpassCharger(at: coordinate)
        await cache.store(key: cacheKey, value: info)
        return info
    }

    /// Belirli bir bölgedeki (rota üzerinde) tüm şarj istasyonlarını tarar.
    /// - Parameters:
    ///   - coordinates: Taranacak koordinat listesi
    ///   - radiusMeters: Her nokta etrafındaki arama yarıçapı
    /// - Returns: [OverpassChargerInfo] — her istasyon için ayrı ayrı
    public func fetchChargersAlongRoute(coordinates: [CLLocationCoordinate2D], radiusMeters: Int = 200) async -> [OverpassChargerInfo] {
        guard !coordinates.isEmpty else { return [] }

        // Her bir koordinat için paralel sorgu
        let results = await withTaskGroup(of: OverpassChargerInfo?.self) { group in
            for coord in coordinates {
                group.addTask {
                    await self.fetchChargerInfo(at: coord)
                }
            }

            var chargers: [OverpassChargerInfo] = []
            for await result in group {
                if let charger = result {
                    chargers.append(charger)
                }
            }
            return chargers
        }

        return results
    }

    // MARK: - Overpass Query

    /// Overpass API'ye sorgu yapıp JSON parse eder.
    /// `out body;` ile detaylı etiket bilgisi alınır.
    private func queryOverpassCharger(at coordinate: CLLocationCoordinate2D) async -> OverpassChargerInfo? {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let radiusMeters = 150

        let query = """
        [out:json];(
          node["amenity"="charging_station"](around:\(radiusMeters),\(lat),\(lon));
          way["amenity"="charging_station"](around:\(radiusMeters),\(lat),\(lon));
        );out body;
        """

        guard let raw = try? await performQuery(query) else { return nil }
        return parseChargerResponse(raw)
    }

    /// Overpass API'ye HTTP isteği yapar.
    private func performQuery(_ overpassQL: String) async throws -> String {
        guard let encoded = overpassQL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)") else {
            throw WizPathError.weatherAPIFailed
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ForeWiz/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WizPathError.weatherAPIFailed
        }
        if httpResponse.statusCode == 429 {
            AppLogger.wizPath.warning("Overpass API rate limited (charger lookup)")
            throw WizPathError.weatherAPIFailed
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw WizPathError.weatherAPIFailed
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Response Parsing

    /// Overpass JSON yanıtını parse ederek konnektör tiplerini çıkarır.
    ///
    /// OSM Tag'lerinden socket tiplerini okur:
    /// ```
    /// socket:type2=2           → 2 adet Type 2 soket
    /// socket:type2_combo=2     → 2 adet CCS (Type 2 Combo) soket
    /// socket:chademo=1         → 1 adet CHAdeMO soket
    /// socket:tesla_supercharger=4 → 4 adet Tesla Supercharger soket
    /// socket:nacs=2            → 2 adet NACS soket
    /// maxpower=350             → 350 kW maksimum güç
    /// capacity=6               → 6 araç kapasitesi
    /// ```
    private func parseChargerResponse(_ json: String) -> OverpassChargerInfo? {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let elements = dict["elements"] as? [[String: Any]],
              !elements.isEmpty else {
            return nil
        }

        var allConnectors = Set<EVConnectorType>()
        var maxPower: Double?
        var totalCapacity = 0
        var operatorName: String?
        var isFast = false

        for element in elements {
            guard let tags = element["tags"] as? [String: String] else { continue }

            // Operatör adı
            if operatorName == nil {
                operatorName = tags["operator"] ?? tags["brand"] ?? tags["network"]
            }

            // Kapasite: OSM'de ya `capacity` (toplam araç yeri) ya da socket sayıları
            if let capStr = tags["capacity"], let cap = Int(capStr), cap > 0 {
                totalCapacity += cap
            } else {
                for (key, valStr) in tags where key.hasPrefix("socket:") {
                    if let count = Int(valStr) {
                        totalCapacity += count
                    } else if !valStr.isEmpty {
                        totalCapacity += 1
                    }
                }
            }

            // Socket tiplerini tara
            for (key, _) in tags {
                let connector = socketTagToConnectorType(key)
                if let type = connector {
                    allConnectors.insert(type)
                }
                // Güç bilgisi
                if key == "maxpower", let powerStr = tags["maxpower"],
                   let power = Double(powerStr.replacingOccurrences(of: " kW", with: "").replacingOccurrences(of: "kW", with: "")) {
                    if maxPower == nil || power > maxPower! {
                        maxPower = power
                        if power >= 150 { isFast = true }
                    }
                }
            }

            // socket:type2=2 gibi değerlerden güç tahmini
            for (key, valStr) in tags where key.hasPrefix("maxpower:") {
                if let power = Double(valStr) {
                    if maxPower == nil || power > maxPower! {
                        maxPower = power
                        if power >= 150 { isFast = true }
                    }
                }
            }
        }
        guard !allConnectors.isEmpty else { return nil }

        return OverpassChargerInfo(
            connectorTypes: Array(allConnectors).sorted { $0.rawValue < $1.rawValue },
            maxPowerKw: maxPower,
            stationCount: elements.count,
            operatorName: operatorName,
            isFastCharger: isFast
        )
    }

    /// OSM socket tag'ini EVConnectorType'a çevirir.
    /// Overpass API'den gelen key'ler örn: "socket:type2_combo", "socket:chademo", "socket:nacs"
    private func socketTagToConnectorType(_ tag: String) -> EVConnectorType? {
        switch tag {
        case "socket:type2_combo", "socket:ccs", "socket:type2_ccs":
            return .ccs
        case "socket:chademo", "socket:CHAdeMO":
            return .chademo
        case "socket:tesla_supercharger", "socket:nacs", "socket:NACS":
            return .teslaNACS
        case "socket:type2", "socket:type2_schuko":
            return .type2
        case "socket:gbt", "socket:gb_t", "socket:GB_T":
            return .gbT
        default:
            // "socket:type2_combo=2" gibi değerlerde Overpass key "socket:type2_combo" olur
            if tag.hasPrefix("socket:type2_combo") || tag.hasPrefix("socket:ccs") { return .ccs }
            if tag.hasPrefix("socket:chademo") { return .chademo }
            if tag.hasPrefix("socket:tesla_supercharger") || tag.hasPrefix("socket:nacs") { return .teslaNACS }
            if tag.hasPrefix("socket:type2") { return .type2 }
            if tag.hasPrefix("socket:gbt") || tag.hasPrefix("socket:gb_t") || tag.hasPrefix("socket:GB_T") { return .gbT }
            return nil
        }
    }
}

// MARK: - Actor-based Cache (thread-safe)

/// Overpass sorguları için 1 saat TTL'li cache.
/// Overpass API rate limit (429) sorununu önlemek için agresif cache.
private actor ChargerOverpassCache {
    private var cache: [String: (value: OverpassChargerInfo, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 3600 // 1 saat

    func retrieve(key: String) -> OverpassChargerInfo? {
        guard let entry = cache[key],
              Date().timeIntervalSince(entry.timestamp) < ttl else {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func store(key: String, value: OverpassChargerInfo?) {
        guard let value else {
            cache.removeValue(forKey: key)
            return
        }
        cache[key] = (value, Date())
    }
}
