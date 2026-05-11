import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String

    let onRecommendationLoaded: (DailyRecommendation) -> Void
    let onOpenSettings: () -> Void

    @State private var showLocationPicker = false
    @State private var showSplash = true
    @State private var contentReady = false
    @State private var toolbarAppeared = false

    private var currentSymbol: String {
        if case .loaded(let state) = viewModel.state { return state.currentWeather.symbolName }
        return "cloud.fill"
    }

    private var splashKind: WeatherSplashKind {
        WeatherSplashKind.from(symbolName: currentSymbol)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground(symbolName: currentSymbol)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: currentSymbol)
                content

                if showSplash {
                    WeatherSplashOverlay(
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
                    onSelect: { location in Task { await viewModel.changeLocation(to: location) } }
                )
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState { onRecommendationLoaded(state.recommendation) }
            }
        }
        .dynamicTypeSize(.large ... .xxxLarge)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                HapticManager.light()
                showLocationPicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.4, green: 0.75, blue: 1.0))
                    Text(viewModel.selectedLocationName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .opacity(toolbarAppeared ? 1 : 0)
            .offset(y: toolbarAppeared ? 0 : -4)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: toolbarAppeared)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.light()
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
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
                UnifiedHeroCard(
                    assistant: state.assistant,
                    weather: state.currentWeather,
                    recommendation: state.recommendation
                )
                .cardEntrance(appeared: contentReady, delay: 0.0)

                if let alert = state.assistant.criticalAlert {
                    CriticalAlertCard(signal: alert)
                        .cardEntrance(appeared: contentReady, delay: 0.08)
                }

                DailyPlanCard(plan: state.plan)
                    .cardEntrance(appeared: contentReady, delay: 0.16)

                CompactHourlyCard(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: contentReady, delay: 0.24)

                CompactForecastCard(dailyForecasts: state.dailyForecasts)
                    .cardEntrance(appeared: contentReady, delay: 0.32)

                if let warning = state.warningMessage {
                    CompactWarningBanner(message: warning)
                        .cardEntrance(appeared: contentReady, delay: 0.40)
                }

                if let attribution = state.attribution {
                    HomeAttributionView(info: attribution)
                        .cardEntrance(appeared: contentReady, delay: 0.48)
                }

                if !state.lastUpdatedText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 9))
                        Text(state.lastUpdatedText)
                            .font(.system(size: 10))
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

    @State private var iconPulse = false

    private var accentColor: Color { AppTheme.toneColor(for: assistant.tone) }
    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }

    var body: some View {
        GlassCard(accentColor: accentColor) {
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(weather.temperatureText)
                            .font(.system(size: 56, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(weather.conditionText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(decisionColor.opacity(0.15))
                            .frame(width: 64, height: 64)
                            .scaleEffect(iconPulse ? 1.08 : 1.0)
                        Image(systemName: assistant.symbolName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(decisionColor)
                            .symbolEffect(.pulse, options: .speed(0.5), value: iconPulse)
                    }
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(decisionColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: decisionColor.opacity(0.8), radius: 5)
                    Text(assistant.headline)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Spacer()
                }

                if let bestWindow = recommendation.bestOutdoorWindow {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(accentColor)
                        Text(bestWindow.shortDisplayText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 6) {
                    metricInline(
                        icon: "thermometer.medium",
                        label: L10n.text("feels_like_short"),
                        value: weather.feelsLikeText
                            .replacingOccurrences(of: L10n.text("weather_feels_like") + " ", with: "")
                    )
                    Spacer()
                    if weather.highTempText != "–" {
                        metricInline(icon: "arrow.up", label: L10n.text("high_label"), value: weather.highTempText)
                        Spacer()
                    }
                    if weather.lowTempText != "–" {
                        metricInline(icon: "arrow.down", label: L10n.text("low_label"), value: weather.lowTempText)
                        Spacer()
                    }
                    metricInline(icon: "humidity.fill", label: L10n.text("humidity"), value: weather.humidityText)
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .onAppear { iconPulse = true }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconPulse)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(weather.temperatureText), \(weather.conditionText). \(assistant.headline)")
    }

    private func metricInline(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(1)
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
                    .fill(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: signal.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.35))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(signal.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.35))
                Text(signal.subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                if !signal.hint.isEmpty {
                    Text(signal.hint)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(
            Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.10),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.25), lineWidth: 1)
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
                            .font(.system(size: 10))
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

private struct PlanItemRow: View {
    let item: HomePlanItem

    private var toneColor: Color { AppTheme.toneColor(for: item.tone) }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(toneColor.opacity(item.isPrimary ? 0.18 : 0.08))
                    .frame(width: 28, height: 28)
                Image(systemName: item.icon)
                    .font(.system(size: 12, weight: item.isPrimary ? .semibold : .medium))
                    .foregroundStyle(toneColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: item.isPrimary ? .bold : .semibold))
                    .foregroundStyle(item.isPrimary ? .white : Color.white.opacity(0.8))
                Text(item.detail)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            Text(item.timeText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(toneColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(toneColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(.vertical, 8)
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
                        ForEach(dailyForecasts.prefix(3)) { forecast in
                            ForecastPill(forecast: forecast)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.horizontal, -16)
            .padding(.vertical, 10)
        }
    }
}

private struct ForecastPill: View {
    let forecast: DailyForecastItem

    private var skyColor: Color {
        let c = forecast.conditionSymbol.lowercased()
        if c.contains("rain") || c.contains("drizzle") { return Color(red: 0.3, green: 0.55, blue: 0.9) }
        if c.contains("sun") || c.contains("clear") { return Color(red: 1.0, green: 0.7, blue: 0.2) }
        if c.contains("cloud") { return Color(red: 0.5, green: 0.55, blue: 0.65) }
        if c.contains("storm") || c.contains("thunder") { return Color(red: 0.6, green: 0.3, blue: 0.8) }
        if c.contains("snow") { return Color(red: 0.7, green: 0.8, blue: 0.9) }
        return Color(red: 0.4, green: 0.72, blue: 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(forecast.dayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(forecast.isToday
                    ? Color(red: 1.0, green: 0.85, blue: 0.3)
                    : Color.white.opacity(0.6))

            Image(systemName: forecast.conditionSymbol)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(skyColor)
                .shadow(color: skyColor.opacity(0.3), radius: 4)

            Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)

            Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.system(size: 10))
                .foregroundStyle(Color.white.opacity(0.4))

            // Skor göstergesi
            ZStack {
                Circle()
                    .stroke(strokeColor(for: WeatherScore(rawValue: forecast.outdoorScore)), lineWidth: 2)
                    .frame(width: 18, height: 18)
                Text(String(forecast.outdoorScore))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func strokeColor(for score: WeatherScore) -> Color {
        switch score.rawValue {
        case 80...100: return Color(red: 0.3, green: 0.85, blue: 0.58)
        case 60..<80: return Color(red: 0.4, green: 0.72, blue: 1.0)
        case 40..<60: return Color(red: 1.0, green: 0.7, blue: 0.3)
        default: return Color(red: 1.0, green: 0.4, blue: 0.4)
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(hourlyScores.prefix(4)) { item in
                            HourlyPill(item: item)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.horizontal, -16)
            .padding(.vertical, 10)
        }
    }
}

private struct HourlyPill: View {
    let item: HourlyScoreItem

    private var color: Color {
        switch item.score {
        case 80...100: Color(red: 0.3, green: 0.85, blue: 0.58)
        case 60..<80: Color(red: 0.4, green: 0.72, blue: 1.0)
        case 40..<60: Color(red: 1.0, green: 0.7, blue: 0.3)
        default: Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d:00", item.hour))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))

            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 22, height: 22)
                Text(String(item.score))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
            }

            Image(systemName: item.symbolName)
                .font(.system(size: 13))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)

            Text(item.temperatureText)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.6))

            if item.precipitationChance > 0.05 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 7))
                    Text(String(format: "%0.0f%%", item.precipitationChance * 100))
                        .font(.system(size: 8, weight: .medium))
                }
                .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.12), lineWidth: 0.5))
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
    }
}

// MARK: - Card entrance modifier

private extension View {
    func cardEntrance(appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .scaleEffect(appeared ? 1 : 0.98)
            .animation(.spring(response: 0.4, dampingFraction: 0.82).delay(delay), value: appeared)
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

private struct HomeLoadingView: View {
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

private struct HomeErrorView: View {
    let message: String
    let retry: () -> Void
    @State private var shake = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.12))
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
                HapticManager.medium()
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
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Attribution

private struct HomeAttributionView: View {
    let info: WeatherAttributionInfo

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
            Text(info.serviceName)
                .font(.system(size: 11))
        }
        .foregroundStyle(Color.white.opacity(0.22))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 8)
    }
}

