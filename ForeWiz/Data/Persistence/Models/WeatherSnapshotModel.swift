import Foundation
import SwiftData

@Model
final class WeatherSnapshotModel {
    @Attribute(.unique) var id: UUID
    var locationLatitude: Double
    var locationLongitude: Double
    var fetchedAt: Date
    var data: Data

    init(snapshot: WeatherSnapshot) throws {
        self.id = UUID()
        self.locationLatitude = snapshot.location.latitude
        self.locationLongitude = snapshot.location.longitude
        self.fetchedAt = snapshot.fetchedAt
        self.data = try JSONEncoder().encode(snapshot)
    }

    func toSnapshot() throws -> WeatherSnapshot {
        try JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }
}
