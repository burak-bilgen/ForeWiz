import SwiftUI

// MARK: - Loaded Content

struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 1. Critical alerts (safety first)
                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.0)
                        .padding(.bottom, 20)
                }

                // 2. Hero card — current conditions + score
                HeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.08)
                .padding(.bottom, 16)

                // 3. Warning banner — between hero and insights
                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                        .padding(.bottom, 20)
                }

                // 4. AI Briefing + Key Events — grouped with section header
                VStack(spacing: 14) {
                    if let briefing = state.briefing {
                        AIBriefingSection(briefing: briefing)
                            .cardEntrance(appeared: contentReady, baseDelay: 0.24)
                    }

                    DayKeyEventsView(events: state.keyEvents)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.28)
                }
                .padding(.bottom, 20)

                // 5. Hourly forecast — time-sensitive
                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)
                    .padding(.bottom, 20)

                // 6. Weekly forecast — planning reference
                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)
                    .padding(.bottom, 24)

                // 7. Footer — attribution + last updated
                if let attribution = state.attribution {
                    CompactFooter(attribution: attribution, lastUpdatedText: state.lastUpdatedText)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.48)
                        .padding(.bottom, 8)
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
