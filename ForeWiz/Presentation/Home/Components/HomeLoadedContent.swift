import SwiftUI

// MARK: - Loaded Content

struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Critical alerts (safety first)
                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.0)
                }

                // 2. Hero card — current conditions + score
                HeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.08)

                // 3. Warning banner
                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                // 4. Key events — today's weather highlights
                DayKeyEventsView(events: state.keyEvents)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.24)

                // 5. Hourly forecast — time-sensitive
                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)

                // 6. Weekly forecast — planning reference
                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)

                // 7. Ad banner — monetization
                if AdManager.shared.canShowBanner() {
                    GlassAdBanner(adUnit: .homeBanner)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.48)
                }

                // 8. Footer — attribution + last updated
                if let attribution = state.attribution {
                    CompactFooter(attribution: attribution, lastUpdatedText: state.lastUpdatedText)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.56)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 12)
        .refreshable { await refresh() }
    }
}
