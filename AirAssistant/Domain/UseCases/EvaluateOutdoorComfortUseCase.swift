import Foundation

protocol EvaluateOutdoorComfortUseCase {
    func execute(snapshot: WeatherSnapshot, profile: UserComfortProfile) async throws -> WeatherScore
}
