import SwiftUI
import WizPathKit

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

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 20) {

                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.0)
                }

                HeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.08)

                WizPathHUDCard(
                    routeStatus: WizPathHUDStatus.shared.currentStatus,
                    onTap: onWizPathTap
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.12)

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

                    CommuteSetupCard(onEditLocations: onEditLocations)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.14)
                }

                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)

                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)

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
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)

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

}
