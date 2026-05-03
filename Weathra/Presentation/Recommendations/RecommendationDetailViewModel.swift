import Combine
import Foundation

@MainActor
final class RecommendationDetailViewModel: ObservableObject {
    @Published private(set) var recommendation: DailyRecommendation

    init(recommendation: DailyRecommendation) {
        self.recommendation = recommendation
    }
}
