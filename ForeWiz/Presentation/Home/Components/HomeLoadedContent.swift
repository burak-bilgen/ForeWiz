import SwiftUI
import WizPathKit

// MARK: - Loaded Content

struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void
    let onWizPathTap: () -> Void
    let onWeatherFeedback: ((UserWeatherFeedback) async -> Void)?
    
    @State private var showNativeAd = false
    @State private var showBannerAd = false
    @State private var insertionPoints: [AdPlacementStrategy.InsertionPoint] = []
    @State private var showWeatherFeedback = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {
                // 1. Critical alerts (safety first)
                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.0)
                }

                // 2. Hero card - current conditions + score
                HeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.08)
                
                // WizPath HUD Card - Center entry point
                WizPathHUDCard(
                    routeStatus: WizPathHUDStatus.shared.currentStatus,
                    onTap: onWizPathTap
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.12)
                
                // Ad insertion point: after hero (rare)
                if let idx = insertionPoints.firstIndex(of: .afterHero) {
                    adSection(at: idx, baseDelay: 0.16)
                }

                // 3. Warning banner
                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                // 4. Weather feedback card
                if showWeatherFeedback, let onWeatherFeedback {
                    WeatherFeedbackCard(
                        onFeedback: { feedback in
                            await onWeatherFeedback(feedback)
                        },
                        onDismiss: {
                            withAnimation(AppTheme.pressSpring) {
                                showWeatherFeedback = false
                            }
                        }
                    )
                    .cardEntrance(appeared: contentReady, baseDelay: 0.20)
                }

                // 5. Key events - today's weather highlights
                DayKeyEventsView(events: state.keyEvents)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.28)
                
                // Ad insertion point: after key events
                if let idx = insertionPoints.firstIndex(of: .afterKeyEvents) {
                    adSection(at: idx, baseDelay: 0.32)
                }

                // 6. Hourly forecast - time-sensitive
                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)
                
                // Ad insertion point: after hourly forecast
                if let idx = insertionPoints.firstIndex(of: .afterHourly) {
                    adSection(at: idx, baseDelay: 0.40)
                }

                // 7. Weekly forecast - planning reference
                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)
                
                // Ad insertion point: after weekly forecast (most common)
                if let idx = insertionPoints.firstIndex(of: .afterWeekly) {
                    adSection(at: idx, baseDelay: 0.48)
                }

                // Footer - attribution + last updated
                if let attribution = state.attribution {
                    // Ad insertion point: before footer
                    if let idx = insertionPoints.firstIndex(of: .beforeFooter) {
                        adSection(at: idx, baseDelay: 0.48)
                    }
                    
                    CompactFooter(attribution: attribution, lastUpdatedText: state.lastUpdatedText)
                        .cardEntrance(appeared: contentReady, baseDelay: insertionPoints.contains(.beforeFooter) ? 0.56 : 0.48)
                } else if let idx = insertionPoints.firstIndex(of: .beforeFooter) {
                    // No footer but ad placed here — just show the ad
                    adSection(at: idx, baseDelay: 0.48)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
            // LazyVStack: ensure contentReady = true triggers entrance for all lazily-created views
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 12)
        .refreshable { await refresh() }
        .onAppear {
            evaluateAdPlacement()
        }
    }
    
    // MARK: - Ad Section
    
    /// Renders exactly ONE ad format at the given insertion point index.
    /// Shows native at index 0, banner at index 1 (never both at the same point).
    @ViewBuilder
    private func adSection(at pointIndex: Int, baseDelay: Double) -> some View {
        let showNativeHere = pointIndex == 0 ? showNativeAd : showBannerAd
        
        if showNativeHere && showNativeAd {
            NativeAdCard()
                .cardEntrance(appeared: contentReady, baseDelay: baseDelay)
        } else if showBannerAd {
            AdBannerView()
                .cardEntrance(appeared: contentReady, baseDelay: baseDelay)
        }
    }
    
    // MARK: - Placement Decision
    
    private func evaluateAdPlacement() {
        // Let the strategy decide IF and WHERE to place ads this time
        insertionPoints = AdPlacementStrategy.shared.decideHomePlacement()
        
        guard !insertionPoints.isEmpty else {
            showNativeAd = false
            showBannerAd = false
            return
        }
        
        // If there are 2 insertion points: native at first, banner at second
        // If there are 2+ insertion points: native at first, banner at second
        if insertionPoints.count >= 2 {
            showNativeAd = AdPlacementStrategy.shared.shouldShowNative(at: .weatherRefresh)
            showBannerAd = AdPlacementStrategy.shared.shouldShowBanner()
        } else {
            // Single insertion point — strategic format selection, never random.
            // Prefer native for revenue; fall back to banner if native is cooling down.
            if AdPlacementStrategy.shared.shouldShowNative(at: .weatherRefresh) {
                showNativeAd = true
                showBannerAd = false
            } else {
                showNativeAd = false
                showBannerAd = AdPlacementStrategy.shared.shouldShowBanner()
            }
        }
        
        // Record shown ads
        if showNativeAd {
            AdPlacementStrategy.shared.recordAdShown(.native)
        }
        if showBannerAd {
            AdPlacementStrategy.shared.recordAdShown(.banner)
        }
        
        // If neither format is available, clear insertion points
        if !showNativeAd && !showBannerAd {
            insertionPoints = []
        }
    }
}
