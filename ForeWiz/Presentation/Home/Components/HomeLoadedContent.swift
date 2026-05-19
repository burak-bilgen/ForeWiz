import SwiftUI

// MARK: - Loaded Content

struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void
    @Binding var showWizPathSheet: Bool
    let wizPathRouteStatus: RouteStatus

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

                // 3. WizPath journey entry
                WizPathHUDCard(
                    routeStatus: wizPathRouteStatus,
                    onTap: {
                        HapticEngine.shared.light()
                        showWizPathSheet = true
                    }
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.12)

                // 4. Warning banner
                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                // 5. Hourly forecast — time-sensitive, placed early
                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.24)

                // 6. AI briefing — narrative, health, comparative, actions
                if let briefing = state.briefing {
                    AIBriefingSection(briefing: briefing)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.32)
                }

                // 7. Weekly forecast — planning reference
                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)

                // 8. Footer — attribution + last updated
                if let attribution = state.attribution {
                    CompactFooter(attribution: attribution, lastUpdatedText: state.lastUpdatedText)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.48)
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
