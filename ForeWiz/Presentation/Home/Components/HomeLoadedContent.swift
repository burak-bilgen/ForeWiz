import SwiftUI
import WizPathKit

// MARK: - Loaded Content

struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void
    let onWizPathTap: () -> Void
    let commuteBriefing: CommuteBriefing?
    let homeName: String?
    let workName: String?
    let travelMode: TravelMode?
    let onEditLocations: () -> Void
    @State private var showNativeAd = false
    @State private var showBannerAd = false
    @State private var insertionPoints: [AdPlacementStrategy.InsertionPoint] = []

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
                
                // Commute Briefing Card - between WizPath and ads
                if let briefing = commuteBriefing, let home = homeName, let work = workName, let mode = travelMode {
                    CommuteBriefingCard(
                        briefing: briefing,
                        homeName: home,
                        workName: work,
                        travelMode: mode,
                        onEditLocations: onEditLocations
                    )
                    .cardEntrance(appeared: contentReady, baseDelay: 0.14)
                } else if homeName == nil || workName == nil {
                    // Show setup card when home or work locations are not set
                    CommuteSetupCard(onEditLocations: onEditLocations)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.14)
                }
                
                // Ad insertion point: after hero (rare)
                if let idx = insertionPoints.firstIndex(of: .afterHero) {
                    adSection(at: idx, baseDelay: 0.16)
                }

                // 3. Warning banner
                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                // 4. Hourly forecast - time-sensitive
                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)
                
                // Ad insertion point: after hourly forecast
                if let idx = insertionPoints.firstIndex(of: .afterHourly) {
                    adSection(at: idx, baseDelay: 0.40)
                }

                // 5. Weekly forecast - planning reference
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
    
    // MARK: - Commute Setup Card

    /// Shown when home or work locations are not configured yet.
    private struct CommuteSetupCard: View {
        let onEditLocations: () -> Void
        @State private var rotationAngle = 0.0

        var body: some View {
            LiquidGlassCard(accentColor: AppTheme.liquidAccent, innerPadding: 0) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.liquidAccent.opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(AppTheme.liquidAccent)
                        }

                        Text(L10n.text("commute_setup_title"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text(L10n.text("commute_setup_body"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            HapticEngine.shared.medium()
                            onEditLocations()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12))
                                Text(L10n.text("commute_setup_button"))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.liquidAccent, Color(hex: "#00D9FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                        }
                        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
                    }
                    .padding(20)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.liquidAccent.opacity(0.3), .clear, AppTheme.liquidAccent.opacity(0.3), .clear, AppTheme.liquidAccent.opacity(0.3)],
                            center: .center,
                            angle: .degrees(rotationAngle)
                        ),
                        lineWidth: 0.8
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360.0
                }
            }
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
