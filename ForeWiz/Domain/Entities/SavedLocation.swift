import Foundation

struct SavedLocation: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String
    var createdAt: Date
    var isFavorite: Bool
    var locationType: LocationType = .other
    var commuteModeRaw: String = "car"
    
    var isHome: Bool { locationType == .home }
    var isWork: Bool { locationType == .work }

    init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double,
        address: String = "",
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        locationType: LocationType = .other,
        commuteModeRaw: String = "car"
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.locationType = locationType
        self.commuteModeRaw = commuteModeRaw
    }

    static var currentLocation: SavedLocation {
        SavedLocation(
            id: "current-location",
            name: L10n.text("home_current_location"),
            latitude: 0,
            longitude: 0,
            address: L10n.text("location_being_determined"),
            isFavorite: true
        )
    }
}
