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

    func toJournalEntry() -> JournalEntry {
        JournalEntry(
            id: id,
            date: date,
            title: title,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            weatherSnapshotData: weatherSnapshotData,
            routeData: routeData,
            healthData: healthData,
            notes: notes,
            createdAt: createdAt,
            typeRaw: typeRaw
        )
    }
}

extension JournalEntryModel {
    convenience init(from entry: JournalEntry) {
        self.init(
            id: entry.id,
            date: entry.date,
            title: entry.title,
            locationName: entry.locationName,
            latitude: entry.latitude,
            longitude: entry.longitude,
            weatherSnapshotData: entry.weatherSnapshotData,
            routeData: entry.routeData,
            healthData: entry.healthData,
            notes: entry.notes,
            createdAt: entry.createdAt,
            typeRaw: entry.typeRaw
        )
    }
}
