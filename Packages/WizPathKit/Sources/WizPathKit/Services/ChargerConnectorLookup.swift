import Foundation
import CoreLocation

// MARK: - EV Charger Connector Lookup

/// 🔌 Apple Maps EV charger konnektör tipi tespiti.
///
/// Apple Maps'in MKMapItem API'si doğrudan konnektör tipi bilgisi vermez.
/// Bu servis, şarj istasyonu **operatör adına** ve **POI kategorisine** göre
/// hangi konnektör tiplerinin mevcut olduğunu tahmin eder.
///
/// **Tamamen statik lookup — API çağrısı yok, ücretsiz.**
/// Veri kaynağı: kamuya açık şarj ağı bilgileri.
public enum ChargerConnectorLookup {

    /// İstasyon adına ve/veya koordinatına göre konnektör tiplerini döndürür.
    /// - Önce Overpass API (gerçek OSM verisi) denenir.
    /// - Overpass başarısız olursa statik lookup'a düşer.
    /// - Parameters:
    ///   - stationName: MKMapItem'den gelen istasyon adı
    ///   - coordinate: İsteğe bağlı koordinat (Overpass sorgusu için)
    /// - Returns: İstasyonda bulunması muhtemel konnektör tipleri
    public static func connectorTypes(forStationName stationName: String?, coordinate: CLLocationCoordinate2D? = nil) async -> [EVConnectorType] {
        // 1. Önce gerçek OSM verisi (Overpass API)
        if let coord = coordinate {
            if let overpassInfo = await OverpassChargerService.shared.fetchChargerInfo(at: coord),
               !overpassInfo.connectorTypes.isEmpty {
                return overpassInfo.connectorTypes
            }
        }
        // 2. Fallback: statik lookup
        return await staticConnectorTypes(forStationName: stationName)
    }

    /// ⚡ Statik lookup — operatör adına göre konnektör tipi tahmini.
    /// Overpass API kullanılamadığında devreye girer.
    private static func staticConnectorTypes(forStationName stationName: String?) async -> [EVConnectorType] {
        guard let name = stationName?.lowercased() else {
            return [.ccs] // Varsayılan: CCS
        }

        // Tesla Supercharger ve Destination Charger → NACS
        if name.contains("tesla") {
            if name.contains("supercharger") || name.contains("destination") {
                return [.teslaNACS]
            }
            return [.teslaNACS, .ccs] // Yeni V4 Supercharger'lar CCS de destekler
        }

        // CHAdeMO ağları
        if name.contains("chademo") {
            return [.chademo]
        }
        if name.contains("nissan") || name.contains("leaf") {
            return [.chademo, .ccs]
        }

        // Japon/Tayvan markaları
        if name.contains("chaoji") || name.contains("chao") {
            return [.ccs, .chademo]
        }

        // GB/T (Çin)
        if name.contains("gbt") || name.contains("gb/t") || name.contains("国标") {
            return [.gbT]
        }
        if name.contains("xiao") || name.contains("nio") || name.contains("xpeng") || name.contains("byd") || name.contains("zeekr") {
            return [.gbT, .ccs]
        }

        // Avrupa/Kore ağları → CCS
        let ccsNetworks = [
            "ionity", "fastned", "allego", "electra", "totalenergies",
            "shell recharge", "bp pulse", "chargepoint", "evbox",
            "eon", "enel", "enel x", "plugsurfing", "maingau",
            "newmotion", "smatrics", "clever", "norway", "fortum",
            "recharge", "gireve", "freshmile", "mobivice",
            "elaway", "ladegrün", "supercharger",
            "kepco", "ekar", "chaevi", "ev充电",
        ]
        for pattern in ccsNetworks {
            if name.contains(pattern) {
                return [.ccs]
            }
        }

        // ABD ağları → CCS (bazıları NACS dönüşümünde)
        let usNetworks = [
            "electrify america", "evgo", "chargepoint", "blink",
            "greenlots", "evconnect", "semaconnect", "volta",
            "flo", "circuit électrique", "opconnect",
        ]
        for pattern in usNetworks {
            if name.contains(pattern) {
                // Tesla Magic Dock istasyonları hem NACS hem CCS
                if name.contains("magic dock") {
                    return [.teslaNACS, .ccs]
                }
                return [.ccs]
            }
        }

        // AC (Type 2) ağları — yavaş şarj
        let type2Networks = [
            "wallbox", "pulsar", "zappi", "mennekes",
            "goingelectric", "park&charge", "ubitricity",
        ]
        for pattern in type2Networks {
            if name.contains(pattern) {
                return [.type2]
            }
        }

        // Hiçbir eşleşme yoksa varsayılan
        return [.ccs]
    }

    /// Belirli bir araç modelinin desteklediği konnektör tiplerini döndürür.
    /// Önce Overpass API (gerçek veri), yoksa statik fallback.
    public static func compatibleConnectors(for vehicle: VehicleModel, stationName: String?, coordinate: CLLocationCoordinate2D? = nil) async -> [EVConnectorType] {
        let stationTypes = await connectorTypes(forStationName: stationName, coordinate: coordinate)
        let vehicleTypes = vehicle.connectorTypes

        // İstasyondaki tiplerle araç tiplerinin kesişimini bul
        let compatible = stationTypes.filter { vehicleTypes.contains($0) }

        // Eğer uyumlu yoksa ama istasyon boş döndüyse, araç tiplerini dene
        if compatible.isEmpty, stationName == nil {
            return vehicleTypes
        }

        return compatible.isEmpty ? stationTypes : compatible
    }

    /// Şarj istasyonu adına göre ortalama hız (kW) tahmini.
    public static func estimatedMaxPowerKw(forStationName stationName: String?) -> Double {
        guard let name = stationName?.lowercased() else { return 120 }

        // Ultra-hızlı (350 kW)
        let ultraFast: [(String, Double)] = [
            ("ionity", 350), ("fastned", 350), ("electrify america 350", 350),
            ("evgo extreme", 350), ("chaevi 350", 350),
        ]
        for (pattern, power) in ultraFast {
            if name.contains(pattern) { return power }
        }

        // Hızlı (150-250 kW)
        let fast: [(String, Double)] = [
            ("supercharger v4", 250), ("supercharger v3", 250),
            ("allego 300", 300), ("bp pulse 300", 300),
            ("shell recharge 175", 175), ("electrify america 150", 150),
            ("evgo 150", 150), ("chaevi 200", 200),
        ]
        for (pattern, power) in fast {
            if name.contains(pattern) { return power }
        }

        // Orta hız (50-120 kW)
        let medium: [(String, Double)] = [
            ("supercharger", 150), ("chargepoint express", 125),
            ("evgo", 100), ("blink", 100), ("greenlots", 100),
            ("nissan", 50), ("chademo", 50),
        ]
        for (pattern, power) in medium {
            if name.contains(pattern) { return power }
        }

        return 120 // Varsayılan
    }

    /// İstasyon adına göre ağ operatörü bilgisi.
    public static func networkName(forStationName stationName: String?) -> String? {
        guard let name = stationName?.lowercased() else { return nil }

        let networks: [(String, String)] = [
            ("tesla", "Tesla"),
            ("ionity", "Ionity"),
            ("fastned", "Fastned"),
            ("allego", "Allego"),
            ("electrify america", "Electrify America"),
            ("evgo", "EVgo"),
            ("chargepoint", "ChargePoint"),
            ("blink", "Blink Charging"),
            ("shell recharge", "Shell Recharge"),
            ("bp pulse", "BP Pulse"),
            ("totalenergies", "TotalEnergies"),
            ("nissan", "Nissan"),
        ]

        for (pattern, network) in networks {
            if name.contains(pattern) { return network }
        }

        return nil
    }
}
