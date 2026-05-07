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
        case .pollen: L10n.text("allergy_pollen")
        case .dust: L10n.text("allergy_dust")
        case .mold: L10n.text("allergy_mold")
        case .petDander: L10n.text("allergy_pet")
        case .smoke: L10n.text("allergy_smoke")
        case .airQuality: L10n.text("allergy_air")
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
        case .grass: L10n.text("pollen_grass")
        case .tree: L10n.text("pollen_tree")
        case .weed: L10n.text("pollen_weed")
        case .olive: L10n.text("pollen_olive")
        }
    }
}