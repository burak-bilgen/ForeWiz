import Foundation

struct SavedLocation: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var address: String
    var createdAt: Date
    var isFavorite: Bool

    init(id: String = UUID().uuidString, name: String, latitude: Double, longitude: Double, address: String = "", createdAt: Date = Date(), isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = createdAt
        self.isFavorite = isFavorite
    }

    static var currentLocation: SavedLocation {
        SavedLocation(id: "current-location", name: "Bulunduğum Konum", latitude: 0, longitude: 0, address: "GPS ile belirleniyor", isFavorite: true)
    }
}
