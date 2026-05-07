import Foundation

enum AllergyType: String, CaseIterable, Codable, Hashable, Sendable {
    case pollen
    case dust
    case mold
    case petDander
    case smoke
    case airQuality

    var localizedTitle: String {
        switch self {
        case .pollen: String(localized: "allergy_pollen")
        case .dust: String(localized: "allergy_dust")
        case .mold: String(localized: "allergy_mold")
        case .petDander: String(localized: "allergy_pet")
        case .smoke: String(localized: "allergy_smoke")
        case .airQuality: String(localized: "allergy_air")
        }
    }

    var icon: String {
        switch self {
        case .pollen: "leaf.fill"
        case .dust: "dust.fill"
        case .mold: "drop.fill"
        case .petDander: "pawprint.fill"
        case .smoke: "smoke.fill"
        case .airQuality: "aqi.medium"
        }
    }
}

struct AllergyProfile: Codable, Equatable, Sendable {
    var allergies: Set<AllergyType>
    var pollenTypes: Set<PollenType>
    var isEnabled: Bool

    init(
        allergies: Set<AllergyType> = [],
        pollenTypes: Set<PollenType> = Set(PollenType.allCases),
        isEnabled: Bool = true
    ) {
        self.allergies = allergies
        self.pollenTypes = pollenTypes
        self.isEnabled = isEnabled
    }

    static var `default`: AllergyProfile {
        AllergyProfile(isEnabled: false)
    }
}

enum PollenType: String, CaseIterable, Codable, Hashable, Sendable {
    case grass
    case tree
    case weed
    case olive

    var localizedTitle: String {
        switch self {
        case .grass: String(localized: "pollen_grass")
        case .tree: String(localized: "pollen_tree")
        case .weed: String(localized: "pollen_weed")
        case .olive: String(localized: "pollen_olive")
        }
    }
}