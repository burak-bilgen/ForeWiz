import SwiftUI
import SwiftData

// MARK: - Liquid Glass Home View
/// Premium weather assistant home screen with Liquid Glass aesthetic.
/// Features animated orb backgrounds, glass cards, micro-interactions, and accessibility.
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String

    let onRecommendationLoaded: (DailyRecommendation) -> Void
    let onOpenSettings: () -> Void
    let onLocationsChanged: ([SavedLocation], String) -> Void

    @State private var showLocationPicker = false
    @State private var showSplash = true
    @State private var contentReady = false
    @State private var toolbarAppeared = false
    @State private var showWizPathSheet = false

    private var wizPathRouteStatus: RouteStatus {
        WizPathHUDStatus.shared.currentStatus
    }

    private var currentSymbol: String {
        if case .loaded(let state) = viewModel.state { return state.currentWeather.symbolName }
        return "cloud.fill"
    }

    private var splashKind: EnhancedWeatherSplashKind {
        EnhancedWeatherSplashKind.from(symbolName: currentSymbol)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidOrbBackground(palette: orbPalette)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.5), value: currentSymbol)

                content

                if showSplash {
                    EnhancedWeatherSplashOverlay(
                        kind: splashKind,
                        onDismiss: { showSplash = false },
                        onFadeOut: {
                            withAnimation(AppTheme.springSmooth) {
                                contentReady = true
                            }
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { toolbarContent }
            .task { viewModel.onAppear() }
            .onAppear { animateToolbar() }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in Task { await viewModel.changeLocation(to: location) } },
                    onLocationsChanged: { locations in onLocationsChanged(locations, selectedLocationID) }
                )
            }
            .fullScreenCover(isPresented: $showWizPathSheet) {
                WizPathDashboardView()
            }
            .onChange(of: showWizPathSheet) { _, isPresented in
                if !isPresented {
                    objectWillChange.send()
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState { onRecommendationLoaded(state.recommendation) }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            ToolbarLocationButton(
                locationName: viewModel.selectedLocationName,
                action: { showLocationPicker = true }
            )
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: toolbarAppeared)
        }

        ToolbarItem(placement: .topBarTrailing) {
            ToolbarSettingsButton(action: onOpenSettings)
                .opacity(toolbarAppeared ? 1 : 0)
                .offset(y: toolbarAppeared ? 0 : -4)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: toolbarAppeared)
        }
    }

    private func animateToolbar() {
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            toolbarAppeared = true
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView()
                .transition(.opacity)
        case .failed(let message):
            HomeErrorView(message: message, retry: { Task { await viewModel.refresh() } })
                .transition(.opacity)
        case .loaded(let state):
            HomeLoadedContent(
                state: state,
                contentReady: contentReady,
                refresh: { await viewModel.refresh() },
                showWizPathSheet: $showWizPathSheet,
                wizPathRouteStatus: $wizPathRouteStatus
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.97)),
                removal: .opacity
            ))
        }
    }

    // MARK: - Orb Palette

    private var orbPalette: LiquidOrbBackground.OrbPalette {
        switch currentSymbol {
        case _ where currentSymbol.contains("storm") || currentSymbol.contains("thunder"):
            return .stormy
        case _ where currentSymbol.contains("snow") || currentSymbol.contains("sleet"):
            return .snowy
        case _ where currentSymbol.contains("rain") || currentSymbol.contains("drizzle"):
            return .default
        case _ where currentSymbol.contains("fog") || currentSymbol.contains("mist"):
            return .default
        case _ where currentSymbol.contains("sun") || currentSymbol.contains("clear"):
            return .clearSky
        case _ where currentSymbol.contains("moon"):
            return .night
        default:
            return .default
        }
    }
}

// MARK: - Loaded Content

private struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void
    @Binding var showWizPathSheet: Bool
    @Binding var wizPathRouteStatus: RouteStatus

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.0)
                }

                HeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation,
                    isUsingCachedWeather: state.isUsingCachedWeather
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.08)

                // WizPath Entry
                WizPathHUDCard(
                    routeStatus: wizPathRouteStatus,
                    onTap: {
                        HapticEngine.shared.light()
                        showWizPathSheet = true
                    }
                )
                .cardEntrance(appeared: contentReady, baseDelay: 0.12)

                if let warning = state.warningMessage {
                    WarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.16)
                }

                DailyPlanCard(plan: state.plan)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.24)

                OutfitCard(outfit: state.recommendation.outfit)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.32)

                HourlyForecastSection(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.40)

                WeeklyForecastSection(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, baseDelay: 0.48)

                if let attribution = state.attribution {
                    AttributionView(info: attribution)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.56)
                }

                if !state.lastUpdatedText.isEmpty {
                    LastUpdatedBadge(text: state.lastUpdatedText)
                        .cardEntrance(appeared: contentReady, baseDelay: 0.60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 12)
        .refreshable { await refresh() }
    }
}

// MARK: - Hero Card

private struct HeroCard: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCachedWeather: Bool

    @State private var iconPulse = false

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }
    private var score: Int { recommendation.outdoorScore.rawValue }

    var body: some View {
        LiquidGlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 14) {
                // Assistant Header
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 6, height: 6)
                            Text(L10n.text("home_assistant_badge"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(accentColor)
                        }

                        // Headline
                        Text(assistant.headline)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)

                        // Summary
                        Text(assistant.summary)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    Spacer()

                    // Score Ring + Icon
                    VStack(spacing: 4) {
                        ZStack {
                            ScoreRingView(score: WeatherScore(rawValue: score), size: 56, lineWidth: 4)
                                .frame(width: 56, height: 56)
                            Image(systemName: assistant.symbolName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(decisionColor)
                                .symbolEffect(.bounce, options: .speed(0.5), value: iconPulse)
                        }
                        Text("\(score)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Action Pills
                HStack(spacing: 10) {
                    ActionPill(
                        icon: "clock.fill",
                        title: assistant.primaryActionTitle,
                        detail: assistant.primaryActionDetail,
                        color: accentColor
                    )

                    ActionPill(
                        icon: isUsingCachedWeather ? "arrow.clockwise.icloud.fill" : "checkmark.icloud.fill",
                        title: L10n.text("home_assistant_data_title"),
                        detail: isUsingCachedWeather
                            ? L10n.text("home_assistant_data_cached")
                            : L10n.text("home_assistant_data_live"),
                        color: isUsingCachedWeather ? AppTheme.warning : AppTheme.success
                    )
                }

                // Weather Metrics
                HStack(alignment: .center, spacing: 12) {
                    // Temperature
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.temperatureText)
                            .font(.system(size: 42, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                        Text(weather.conditionText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(2)
                    }
                    .frame(minWidth: 70, alignment: .leading)

                    Spacer()

                    // Metric Grid
                    HStack(spacing: 0) {
                        MetricCell(icon: "thermometer.medium", value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: ""), label: L10n.text("home_metric_feels"))
                        if weather.highTempText != "–" {
                            MetricCell(icon: "arrow.up", value: weather.highTempText, label: L10n.text("home_metric_high"))
                        }
                        if weather.lowTempText != "–" {
                            MetricCell(icon: "arrow.down", value: weather.lowTempText, label: L10n.text("home_metric_low"))
                        }
                        MetricCell(icon: "humidity.fill", value: weather.humidityText, label: L10n.text("home_metric_humidity"))
                    }
                }

                // Sunrise/Sunset
                if weather.sunriseText != nil || weather.sunsetText != nil {
                    HStack(spacing: 12) {
                        if let sunrise = weather.sunriseText {
                            SunTimeRow(icon: "sunrise.fill", color: .orange, time: sunrise)
                        }
                        if weather.sunriseText != nil, weather.sunsetText != nil {
                            Spacer()
                        }
                        if let sunset = weather.sunsetText {
                            SunTimeRow(icon: "sunset.fill", color: .red.opacity(0.8), time: sunset)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .onAppear { iconPulse = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_hero_weather_template", weather.temperatureText, weather.conditionText, assistant.headline))
    }
}

// MARK: - Supporting Views

private struct ActionPill: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct MetricCell: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)
        }
        .frame(minWidth: 40)
    }
}

private struct SunTimeRow: View {
    let icon: String
    let color: Color
    let time: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(time)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

// MARK: - Critical Alert Card

private struct CriticalAlertCard: View {
    let signal: HomeAssistantSignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: signal.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.danger)
                Text(signal.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                if !signal.hint.isEmpty {
                    Text(signal.hint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.danger.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.danger.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Warning Banner

private struct WarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.warning.opacity(0.2))
                    .frame(width: 30, height: 30)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.warning)
            }
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.warning.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.warning.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_warning_banner_template", message))
    }
}

// MARK: - Daily Plan Card

private struct DailyPlanCard: View {
    let plan: HomePlanViewState

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.teal) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(plan.subtitle)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(plan.items.enumerated()), id: \.element.id) { index, item in
                        PlanItemRow(item: item)
                        if index < plan.items.count - 1 {
                            Divider()
                                .background(.white.opacity(0.05))
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
    }
}

private struct PlanItemRow: View {
    let item: HomePlanItem

    private var toneColor: Color {
        switch item.tone {
        case .good: AppTheme.success
        case .caution: AppTheme.warning
        case .danger: AppTheme.danger
        case .info: AppTheme.liquidAccent
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(toneColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: item.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(toneColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.timeText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(toneColor)
            }

            Spacer()

            Text(item.detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .frame(maxWidth: 120, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.leading, 4)
    }
}

// MARK: - Outfit Card

private struct OutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.ember) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.ember.opacity(0.16))
                            .frame(width: 36, height: 36)
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.ember)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text("home_outfit_card_title"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L10n.text("home_outfit_card_subtitle"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(outfit.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if !outfit.items.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(outfit.items.prefix(4), id: \.self) { item in
                            Text(item)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.08), in: Capsule())
                        }
                    }
                }

                if !outfit.accessories.isEmpty {
                    Label(
                        outfit.accessories.prefix(3).joined(separator: ", "),
                        systemImage: "sparkles"
                    )
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                }

                if let warning = outfit.warning {
                    Label(warning, systemImage: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.warning)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("accessibility_outfit_template", outfit.title))
    }
}

// MARK: - Hourly Forecast Section

private struct HourlyForecastSection: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.royalPurple) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("home_hourly_label"), systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                if !hourlyScores.isEmpty {
                    TemperatureTrendChart(hourlyScores: hourlyScores)
                        .frame(height: 130)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(hourlyScores) { item in
                            HourlyPill(item: item)
                        }
                    }
                }
            }
        }
    }
}

private struct HourlyPill: View {
    let item: HourlyScoreItem

    private var scoreColor: Color {
        switch item.score {
        case 70...100: AppTheme.success
        case 40..<70: AppTheme.warning
        default: AppTheme.danger
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(item.hour)\(L10n.text("time_format_hour"))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Image(systemName: item.symbolName)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))

            Text(item.temperatureText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            RoundedRectangle(cornerRadius: 2)
                .fill(scoreColor)
                .frame(width: 16, height: 3)

            Text("\(item.score)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Weekly Forecast Section

private struct WeeklyForecastSection: View {
    let dailyForecasts: [DailyForecastItem]

    var body: some View {
        LiquidGlassCard(accentColor: AppTheme.sky) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("home_forecast_label"), systemImage: "calendar")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                ForEach(dailyForecasts.prefix(7)) { forecast in
                    ForecastRow(forecast: forecast)
                    if forecast.id != dailyForecasts.prefix(7).last?.id {
                        Divider()
                            .background(.white.opacity(0.04))
                    }
                }
            }
        }
    }
}

private struct ForecastRow: View {
    let forecast: DailyForecastItem

    private var scoreColor: Color {
        switch forecast.outdoorScore {
        case 70...100: AppTheme.success
        case 40..<70: AppTheme.warning
        default: AppTheme.danger
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(forecast.dayName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(forecast.isToday ? .white : .white.opacity(0.6))
                .frame(width: 56, alignment: .leading)

            Image(systemName: forecast.conditionSymbol)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)

            HStack(spacing: 4) {
                Text("\(Int(forecast.highTemp))\(L10n.text("unit_degree"))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Int(forecast.lowTemp))\(L10n.text("unit_degree"))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(width: 60)

            Spacer()

            if forecast.precipitationChance > 0.05 {
                HStack(spacing: 3) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 8))
                    Text("\(Int(forecast.precipitationChance * 100))\(L10n.text("unit_percent"))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(AppTheme.sky)
                .frame(width: 44)
            }

            // Score bar
            RoundedRectangle(cornerRadius: 2)
                .fill(scoreColor.opacity(0.6))
                .frame(width: 2, height: 20)

            Text("\(forecast.outdoorScore)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

// MARK: - Misc Views

private struct AttributionView: View {
    let info: WeatherAttributionInfo

    var body: some View {
        VStack(spacing: 4) {
            Text(L10n.formatted("home_attribution_powered", info.serviceName))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
            if let legal = info.legalAttributionText, !legal.isEmpty {
                Text(legal)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.15))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }
}

private struct LastUpdatedBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 10))
            Text(L10n.formatted("home_attribution_updated", text))
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.18))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 4)
    }
}

// MARK: - Temperature Trend Chart

private struct TemperatureTrendChart: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        GeometryReader { geometry in
            let values = hourlyScores.prefix(12)
            guard values.count > 1 else { return AnyView(EmptyView()) }

            let temps = values.map { extractTemp($0.temperatureText) }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 1
            let range = max(maxTemp - minTemp, 1)
            let spacing = geometry.size.width / CGFloat(values.count - 1)

            let points: [CGPoint] = temps.enumerated().map { (i, t) in
                let x = CGFloat(i) * spacing
                let y = geometry.size.height - ((t - minTemp) / range) * (geometry.size.height - 20) - 10
                return CGPoint(x: x, y: y)
            }

            return AnyView(
                ZStack {
                    // Gradient fill
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
                        for p in points {
                            path.addLine(to: p)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.sky.opacity(0.2), AppTheme.sky.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let mid = CGPoint(
                                x: (points[i-1].x + points[i].x) / 2,
                                y: (points[i-1].y + points[i].y) / 2
                            )
                            path.addQuadCurve(to: mid, control: points[i-1])
                            let mid2 = CGPoint(
                                x: (points[i].x + points[min(i+1, points.count-1)].x) / 2,
                                y: (points[i].y + points[min(i+1, points.count-1)].y) / 2
                            )
                            path.addQuadCurve(to: points[i], control: mid2)
                        }
                    }
                    .stroke(AppTheme.sky, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            )
        }
    }

    private func extractTemp(_ text: String) -> CGFloat {
        let digits = text.filter { $0.isNumber || $0 == "." || $0 == "-" }
        return CGFloat(Double(digits) ?? 0)
    }
}

// MARK: - Loading & Error Views

struct HomeLoadingView: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            PulsingDotsLoader(color: .white.opacity(0.5), dotSize: 10)
                .floating(amplitude: 6)
            Text(L10n.text("home_loading_text"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { appeared = true }
    }
}

struct HomeErrorView: View {
    let message: String
    let retry: () -> Void
    @State private var shake = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 80, height: 80)
                Image(systemName: "cloud.slash.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.coral)
                    .symbolRenderingMode(.hierarchical)
            }
            .offset(x: shake ? -8 : 0)
            .onAppear {
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(4)) { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
            }

            VStack(spacing: 10) {
                Text(L10n.text("home_loading_error_title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 24)
            }

            LiquidGlassButton(L10n.text("home_error_retry"), icon: "arrow.clockwise", style: .primary, haptic: .medium) {
                retry()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(for: UserPreferencesModel.self, WeatherSnapshotModel.self)
    let modelContext = container.mainContext
    let preferencesRepo = SwiftDataPreferencesRepository(modelContext: modelContext)
    let weatherCacheRepo = SwiftDataWeatherCacheRepository(modelContext: modelContext)
    let dateProvider = SystemDateProvider()
    let activityEngine = DefaultActivityWindowScoringEngine()
    let outfitEngine = DefaultOutfitDecisionEngine()
    let weatherEngine = DefaultWeatherDecisionEngine(
        activityWindowScoringEngine: activityEngine,
        outfitDecisionEngine: outfitEngine
    )
    HomeView(
        viewModel: HomeViewModel(
            loadHomeRecommendationUseCase: DefaultLoadHomeRecommendationUseCase(
                locationRepository: MockLocationRepository(),
                weatherRepository: MockWeatherRepository(),
                weatherCacheRepository: weatherCacheRepo,
                preferencesRepository: preferencesRepo,
                weatherDecisionEngine: weatherEngine,
                dateProvider: dateProvider
            ),
            scheduleSmartNotificationsUseCase: DefaultScheduleSmartNotificationsUseCase(
                notificationRepository: UserNotificationRepository(),
                notificationPlanningEngine: DefaultNotificationPlanningEngine(),
                dateProvider: dateProvider
            ),
            preferencesRepository: preferencesRepo
        ),
        savedLocations: .constant([]),
        selectedLocationID: .constant("current"),
        onRecommendationLoaded: { _ in },
        onOpenSettings: {},
        onLocationsChanged: { _, _ in }
    )
}
