import Foundation
import SwiftData

@Model
final class JournalEntryModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var locationName: String?
    var latitude: Double
    var longitude: Double
    var weatherSnapshotData: Data?
    var routeData: Data?
    var healthData: Data?
    var notes: String?
    var createdAt: Date
    var typeRaw: String

    init(id: UUID = UUID(), date: Date, title: String, locationName: String? = nil,
         latitude: Double = 0, longitude: Double = 0,
         weatherSnapshotData: Data? = nil, routeData: Data? = nil,
         healthData: Data? = nil, notes: String? = nil,
         createdAt: Date = Date(), typeRaw: String = "trip") {
        self.id = id
        self.date = date
        self.title = title
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.weatherSnapshotData = weatherSnapshotData
        self.routeData = routeData
        self.healthData = healthData
        self.notes = notes
        self.createdAt = createdAt
        self.typeRaw = typeRaw
    }
}
