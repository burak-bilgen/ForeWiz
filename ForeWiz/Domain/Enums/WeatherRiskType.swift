import Foundation

enum WeatherRiskType: String, CaseIterable, Codable, Hashable, Sendable {
    case heat
    case uv
    case rain
    case wind
    case humidity
    case cold
    case storm
    case poorComfort
}
