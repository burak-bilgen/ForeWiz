import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<HomeViewState> = .idle

    private let recommendation: DailyRecommendation

    init(recommendation: DailyRecommendation) {
        self.recommendation = recommendation
    }

    func onAppear() {
        state = .loaded(
            HomeViewState(
                recommendation: recommendation,
                lastUpdatedText: "Son güncelleme: şimdi"
            )
        )
    }
}
