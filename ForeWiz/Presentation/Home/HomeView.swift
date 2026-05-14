import SwiftUI

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
                HomeBackground(symbolName: currentSymbol)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: currentSymbol)
                content

                if showSplash {
                    EnhancedWeatherSplashOverlay(
                        kind: splashKind,
                        onDismiss: { showSplash = false },
                        onFadeOut: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    toolbarAppeared = true
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in Task { await viewModel.changeLocation(to: location) } },
                    onLocationsChanged: { locations in onLocationsChanged(locations, selectedLocationID) }
                )
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState { onRecommendationLoaded(state.recommendation) }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                Task { await HapticEngine.shared.light() }
                showLocationPicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.4, green: 0.75, blue: 1.0))
                    Text(viewModel.selectedLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .accessibilityLabel("Choose location")
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: toolbarAppeared)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await HapticEngine.shared.light() }
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .accessibilityLabel("Open settings")
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(.easeOut(duration: 0.4).delay(0.15), value: toolbarAppeared)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView()
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
        case .failed(let message):
            HomeErrorView(message: message, retry: { Task { await viewModel.refresh() } })
                .transition(.opacity)
        case .loaded(let state):
            HomeLoadedContent(
                state: state,
                contentReady: contentReady,
                refresh: { await viewModel.refresh() }
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.97)).animation(.spring(response: 0.4, dampingFraction: 0.85)),
                removal: .opacity
            ))
        }
    }
}

// MARK: - Loaded content

private struct HomeLoadedContent: View {
    let state: HomeViewState
    let contentReady: Bool
    let refresh: () async -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, delay: 0.0)
                }

                UnifiedHeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation,
                    isUsingCachedWeather: state.isUsingCachedWeather
                )
                .cardEntrance(appeared: contentReady, delay: 0.08)

                if let warning = state.warningMessage {
                    CompactWarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, delay: 0.16)
                }

                DailyPlanCard(plan: state.plan)
                    .cardEntrance(appeared: contentReady, delay: 0.24)

                OutfitSuggestionCard(outfit: state.recommendation.outfit)
                    .cardEntrance(appeared: contentReady, delay: 0.32)

                CompactHourlyCard(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, delay: 0.40)

                CompactForecastCard(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, delay: 0.48)

                if let attribution = state.attribution {
                    HomeAttributionView(info: attribution)
                        .cardEntrance(appeared: contentReady, delay: 0.56)
                }

                if !state.lastUpdatedText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12))
                        Text(state.lastUpdatedText)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.white.opacity(0.22))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
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

// MARK: - Unified Hero Card

private struct UnifiedHeroCard: View {
    let assistant: HomeAssistantViewState
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCachedWeather: Bool

    @State private var iconPulse = false

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }

    var body: some View {
        GlassCard(accentColor: accentColor) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                            Text(L10n.text("home_assistant_badge"))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(accentColor)
                        .textCase(.uppercase)

                        Text(assistant.headline)
                            .font(.system(size: 25, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.85)

                        Text(assistant.summary)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.68))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)

                    ZStack {
                        Circle()
                            .fill(decisionColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                            .scaleEffect(iconPulse ? 1.08 : 1.0)
                        Image(systemName: assistant.symbolName)
                            .font(.system(size: 27, weight: .semibold))
                            .foregroundStyle(decisionColor)
                            .symbolEffect(.pulse, options: .speed(0.5), value: iconPulse)
                    }
                }

                HStack(spacing: 10) {
                    assistantActionPill(
                        icon: "clock.fill",
                        title: assistant.primaryActionTitle,
                        detail: assistant.primaryActionDetail,
                        color: accentColor
                    )

                    assistantActionPill(
                        icon: isUsingCachedWeather ? "arrow.clockwise.icloud.fill" : "checkmark.icloud.fill",
                        title: L10n.text("home_assistant_data_title"),
                        detail: isUsingCachedWeather
                            ? L10n.text("home_assistant_data_cached")
                            : L10n.text("home_assistant_data_live"),
                        color: isUsingCachedWeather ? AppTheme.warning : AppTheme.success
                    )
                }

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.temperatureText)
                            .font(.system(size: 38, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .accessibilityLabel(L10n.formatted("home.accessibility.temperature", weather.temperatureText))
                        Text(weather.conditionText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .lineLimit(2)
                            .accessibilityLabel(L10n.formatted("home.accessibility.condition", weather.conditionText))
                    }
                    .frame(minWidth: 78, alignment: .leading)

                    Spacer()

                    metricInline(
                        icon: "thermometer.medium",
                        label: L10n.text("feels_like_short"),
                        value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: "")
                    )

                    if weather.highTempText != "–" {
                        metricInline(icon: "arrow.up", label: L10n.text("high_label"), value: weather.highTempText)
                    }

                    if weather.lowTempText != "–" {
                        metricInline(icon: "arrow.down", label: L10n.text("low_label"), value: weather.lowTempText)
                    }

                    metricInline(icon: "humidity.fill", label: L10n.text("humidity"), value: weather.humidityText)
                }

                if weather.sunriseText != nil || weather.sunsetText != nil {
                    HStack(spacing: 12) {
                        if let sunrise = weather.sunriseText {
                            HStack(spacing: 4) {
                                Image(systemName: "sunrise.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
                                Text(sunrise)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }
                        if weather.sunriseText != nil, weather.sunsetText != nil {
                            Spacer()
                        }
                        if let sunset = weather.sunsetText {
                            HStack(spacing: 4) {
                                Image(systemName: "sunset.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.2))
                                Text(sunset)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
            }
            .padding(14)
        }
        .onAppear {
            iconPulse = true
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconPulse)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.formatted("home.accessibility.summary", weather.temperatureText, weather.conditionText, assistant.headline))
    }

    private func assistantActionPill(icon: String, title: String, detail: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
            }
            .layoutPriority(1)
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

    private func metricInline(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(minWidth: 44)
    }
}

// MARK: - Critical Alert Card

private struct CriticalAlertCard: View {
    let signal: HomeAssistantSignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: signal.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.danger)
                Text(signal.subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                if !signal.hint.isEmpty {
                    Text(signal.hint)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(
            AppTheme.danger.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.danger.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Daily Plan Card

private struct DailyPlanCard: View {
    let plan: HomePlanViewState

    var body: some View {
        GlassCard(accentColor: Color(red: 0.35, green: 0.82, blue: 0.66)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text(plan.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.3))
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(plan.items.enumerated()), id: \.element.id) { index, item in
                        PlanItemRow(item: item)
                        if index < plan.items.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 36)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}

private struct OutfitSuggestionCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        GlassCard(accentColor: Color(red: 1.0, green: 0.68, blue: 0.32)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.68, blue: 0.32).opacity(0.16))
                            .frame(width: 34, height: 34)
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.35))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.text("home_outfit_card_title"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                        Text(L10n.text("home_outfit_card_subtitle"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.48))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(outfit.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    if outfit.items.isEmpty == false {
                        Text(L10n.formatted("home_outfit_items_intro", outfit.items.prefix(4).joined(separator: ", ")))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if outfit.accessories.isEmpty == false || outfit.warning != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if outfit.accessories.isEmpty == false {
                            Label(
                                L10n.formatted("home_outfit_accessories", outfit.accessories.prefix(3).joined(separator: ", ")),
                                systemImage: "sparkles"
                            )
                        }

                        if let warning = outfit.warning {
                            Label(warning, systemImage: "exclamationmark.circle.fill")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .labelStyle(.titleAndIcon)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.text("home_outfit_card_title")). \(outfit.title)")
    }
}

// MARK: - Forecast Card

private struct CompactForecastCard: View {
    let dailyForecasts: [DailyForecastItem]

    var body: some View {
        GlassCard(accentColor: Color(red: 0.4, green: 0.72, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.text("home_forecast_label"), systemImage: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.horizontal, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dailyForecasts) { forecast in
                            ForecastPill(forecast: forecast)
                        }
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Kompakt saatlik kart

private struct CompactHourlyCard: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        GlassCard(accentColor: Color(red: 0.75, green: 0.5, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 10) {
                Label(L10n.text("home_hourly_label"), systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.horizontal, 12)

                if !hourlyScores.isEmpty {
                    TemperatureTrendChart(hourlyScores: hourlyScores)
                        .padding(.horizontal, 8)
                        .frame(height: 140)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(hourlyScores) { item in
                            HourlyPill(item: item)
                        }
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}

// MARK: - Kompakt uyarı

private struct CompactWarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2))
            }
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.2), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warning: \(message)")
    }
}

// MARK: - Background

private struct HomeBackground: View {
    var symbolName: String = "cloud.fill"

    private var orbColors: (Color, Color, Color) {
        if symbolName.contains("storm") || symbolName.contains("thunder") {
            return (Color(red: 0.45, green: 0.20, blue: 0.90), Color(red: 0.25, green: 0.10, blue: 0.70), Color(red: 0.60, green: 0.30, blue: 1.0))
        }
        if symbolName.contains("snow") || symbolName.contains("sleet") {
            return (Color(red: 0.55, green: 0.80, blue: 1.0), Color(red: 0.35, green: 0.60, blue: 0.90), Color(red: 0.80, green: 0.90, blue: 1.0))
        }
        if symbolName.contains("rain") || symbolName.contains("drizzle") {
            return (Color(red: 0.20, green: 0.40, blue: 0.85), Color(red: 0.10, green: 0.25, blue: 0.70), Color(red: 0.35, green: 0.55, blue: 1.0))
        }
        if symbolName.contains("fog") || symbolName.contains("mist") {
            return (Color(red: 0.50, green: 0.55, blue: 0.65), Color(red: 0.35, green: 0.40, blue: 0.55), Color(red: 0.60, green: 0.65, blue: 0.72))
        }
        if symbolName.contains("sun") || symbolName.contains("clear") {
            return (Color(red: 1.0, green: 0.60, blue: 0.10), Color(red: 0.90, green: 0.35, blue: 0.05), Color(red: 1.0, green: 0.80, blue: 0.30))
        }
        return (Color(red: 0.25, green: 0.48, blue: 0.92), Color(red: 0.15, green: 0.32, blue: 0.75), Color(red: 0.40, green: 0.65, blue: 1.0))
    }

    var body: some View {
        AnimatedOrbBackground(
            primary: orbColors.0,
            secondary: orbColors.1,
            tertiary: orbColors.2
        )
        .animation(.easeInOut(duration: 1.5), value: symbolName)
    }
}

// MARK: - Loading

struct HomeLoadingView: View {
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                SkeletonCard(height: 180)
                    .staggerEntrance(index: 0, appeared: appeared)
                SkeletonCard(height: 120)
                    .staggerEntrance(index: 1, appeared: appeared)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation { appeared = true } }
    }
}

private struct SkeletonCard: View {
    var height: CGFloat
    @State private var shimmerOffset: CGFloat = -300

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0),
                                .white.opacity(0.1),
                                .white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80)
                    .offset(x: shimmerOffset)
                    .blur(radius: 16)
                    .allowsHitTesting(false)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8).repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = 300
                }
            }
    }
}

// MARK: - Error

struct HomeErrorView: View {
    let message: String
    let retry: () -> Void
    @State private var shake = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(AppTheme.danger.opacity(0.12))
                    .frame(width: 90, height: 90)
                    .blur(radius: 8)
                Color.clear
                    .frame(width: 80, height: 80)
                    .glassEffect(.regular, in: Circle())
                Image(systemName: "cloud.slash.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.42))
                    .symbolRenderingMode(.hierarchical)
            }
            .offset(x: shake ? -6 : 0)
            .onAppear {
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(4)) { shake = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
            }

            VStack(spacing: 10) {
                Text(L10n.text("home_loading_error_title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                Task { await HapticEngine.shared.medium() }
                retry()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L10n.text("home_error_retry"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassEffect(.regular, in: Capsule())
            }
            .buttonStyle(.fullTapArea)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
