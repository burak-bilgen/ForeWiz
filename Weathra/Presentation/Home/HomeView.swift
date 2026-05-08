import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String

    let isPremium: Bool
    let store: StoreKitSubscriptionManager
    let onRecommendationLoaded: (DailyRecommendation) -> Void

    @State private var showLocationPicker = false
    @State private var showPaywall = false

    private var currentSymbol: String {
        if case .loaded(let state) = viewModel.state { return state.currentWeather.symbolName }
        return "cloud.fill"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground(symbolName: currentSymbol)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.2), value: currentSymbol)
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { viewModel.onAppear() }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in Task { await viewModel.changeLocation(to: location) } }
                )
            }
            .sheet(isPresented: $showPaywall) { PaywallView(store: store) }
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
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView().transition(.opacity)
        case .failed(let message):
            HomeErrorView(message: message, retry: { Task { await viewModel.refresh() } })
                .transition(.opacity)
        case .loaded(let state):
            HomeLoadedContent(
                state: state,
                isPremium: isPremium,
                onUpgradeTap: { showPaywall = true },
                refresh: { await viewModel.refresh() }
            )
            .transition(.opacity.animation(.easeInOut(duration: 0.4)))
        }
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
            VStack(spacing: 16) {
                // Hero skeleton
                SkeletonCard(height: 220)
                    .staggerEntrance(index: 0, appeared: appeared)

                // Hourly scroll skeleton
                SkeletonCard(height: 110)
                    .staggerEntrance(index: 1, appeared: appeared)

                // Forecast skeleton
                SkeletonCard(height: 180)
                    .staggerEntrance(index: 2, appeared: appeared)

                // Activity skeleton
                SkeletonCard(height: 130)
                    .staggerEntrance(index: 3, appeared: appeared)

                // Outfit skeleton
                SkeletonCard(height: 100)
                    .staggerEntrance(index: 4, appeared: appeared)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation { appeared = true } }
    }
}

private struct SkeletonCard: View {
    var height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.07))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    SkeletonLine(width: 0.4, height: 12)
                    SkeletonLine(width: 0.7, height: 20)
                    SkeletonLine(width: 0.55, height: 12)
                    Spacer()
                    SkeletonLine(width: 0.9, height: 10)
                }
                .padding(20)
            )
            .skeleton()
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

private struct SkeletonLine: View {
    var width: CGFloat  // 0...1 fraction
    var height: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .frame(width: geo.size.width * width, height: height)
        }
        .frame(height: height)
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
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
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
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loaded content

private struct HomeLoadedContent: View {
    let state: HomeViewState
    let isPremium: Bool
    let onUpgradeTap: () -> Void
    let refresh: () async -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HomeHeroCard(weather: state.currentWeather, recommendation: state.recommendation, isUsingCached: state.isUsingCachedWeather)
                    .cardEntrance(appeared: appeared, delay: 0.04)

                if let warning = state.warningMessage {
                    HomeWarningBanner(message: warning).cardEntrance(appeared: appeared, delay: 0.08)
                }

                HomeHourlyCard(hourlyScores: state.hourlyScores)
                    .cardEntrance(appeared: appeared, delay: 0.12)

                HomeForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium, onUpgradeTap: onUpgradeTap)
                    .cardEntrance(appeared: appeared, delay: 0.16)

                if !isPremium {
                    AdBannerView(isPremium: false, onRemoveAdsTapped: onUpgradeTap)
                        .cardEntrance(appeared: appeared, delay: 0.19)
                }

                if !state.recommendation.bestActivityWindows.isEmpty {
                    HomeActivityCard(recommendations: state.recommendation.bestActivityWindows)
                        .cardEntrance(appeared: appeared, delay: 0.22)
                }

                HomeOutfitCard(outfit: state.recommendation.outfit)
                    .cardEntrance(appeared: appeared, delay: 0.26)

                if !state.recommendation.risks.isEmpty {
                    HomeRiskCard(risks: state.recommendation.risks)
                        .cardEntrance(appeared: appeared, delay: 0.30)
                }

                if let attribution = state.attribution {
                    HomeAttributionView(info: attribution)
                        .cardEntrance(appeared: appeared, delay: 0.33)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
        .refreshable { await refresh() }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

// MARK: - Card entrance modifier

private extension View {
    func cardEntrance(appeared: Bool, delay: Double) -> some View {
        self
            .offset(y: appeared ? 0 : 28)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.52, dampingFraction: 0.82).delay(delay), value: appeared)
    }
}

// MARK: - Shared card chrome

private struct GlassCard<Content: View>: View {
    var accentColor: Color = Color(red: 0.4, green: 0.7, blue: 1.0)
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.22), Color.white.opacity(0.04)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
    }
}

private struct CardSectionHeader: View {
    let title: String
    let icon: String
    var color: Color = Color(red: 0.4, green: 0.7, blue: 1.0)

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
                .textCase(.uppercase)
                .tracking(0.7)
        }
    }
}

// MARK: - Hero card

private struct HomeHeroCard: View {
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCached: Bool

    private let sky = Color(red: 0.4, green: 0.72, blue: 1.0)

    var body: some View {
        GlassCard(accentColor: sky) {
            VStack(spacing: 0) {
                // Top: temperature + icon
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weather.temperatureText)
                            .font(.system(size: 76, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        HStack(spacing: 10) {
                            Text(weather.conditionText)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.8))
                            HStack(spacing: 4) {
                                Text("H:\(weather.highTempText)")
                                Text("L:\(weather.lowTempText)")
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.4))
                        }
                        Text(weather.feelsLikeText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .padding(.top, 1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 60))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(sky)
                            .shadow(color: sky.opacity(0.45), radius: 20, x: 0, y: 8)
                            .floating(amplitude: 6, duration: 3.2)
                        if isUsingCached {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 9))
                                Text(L10n.text("home_cached_label"))
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Color.white.opacity(0.3))
                        }
                    }
                }

                // Metrics row
                HStack(spacing: 0) {
                    MetricPill(icon: "humidity.fill", value: weather.humidityText, color: sky)
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
                    Spacer()
                    MetricPill(icon: "wind", value: weather.windText, color: sky)
                    Spacer()
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
                    Spacer()
                    MetricPill(icon: "sun.max.fill", value: "UV \(weather.uvIndexText)", color: Color(red: 1.0, green: 0.7, blue: 0.3))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.top, 16)

                // Divider
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1).padding(.top, 16)

                // Decision row
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(decisionColor)
                                .frame(width: 8, height: 8)
                                .shadow(color: decisionColor.opacity(0.7), radius: 4)
                            Text(recommendation.outdoorDecision.localizedTitle)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Text(recommendation.summaryText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .lineLimit(2)
                        if let best = recommendation.bestOutdoorWindow {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill").font(.system(size: 10))
                                Text(best.shortDisplayText).font(.system(size: 12))
                            }
                            .foregroundStyle(sky)
                        }
                    }
                    Spacer()
                    ScoreRingView(score: recommendation.outdoorScore, size: 72, showOutOf100: true)
                        .environment(\.colorScheme, .dark)
                }
                .padding(.top, 16)
            }
        }
    }

    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }
}

private struct MetricPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Warning banner

private struct HomeWarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.2))
            }
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - Hourly card (Apple Weather style)

private struct HomeHourlyCard: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_hourly_label"), icon: "clock.fill")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(hourlyScores.prefix(24), id: \.hour) { item in
                            HourlyScoreCell(item: item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct HourlyScoreCell: View {
    let item: HourlyScoreItem

    private var color: Color {
        switch item.score {
        case 80...100: return Color(red: 0.3, green: 0.85, blue: 0.6)
        case 60..<80:  return Color(red: 0.4, green: 0.72, blue: 1.0)
        case 40..<60:  return Color(red: 1.0, green: 0.7, blue: 0.3)
        default:       return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }

    private var sfSymbol: String {
        switch item.score {
        case 80...100: return "sun.max.fill"
        case 60..<80:  return "cloud.sun.fill"
        case 40..<60:  return "cloud.fill"
        default:       return "cloud.rain.fill"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(String(format: "%02d", item.hour))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.45))

            Image(systemName: sfSymbol)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 5, height: 40)
                Capsule()
                    .fill(color.opacity(0.75))
                    .frame(width: 5, height: max(4, CGFloat(item.score) * 0.40))
            }

            Text("\(item.score)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(width: 44)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(item.score >= 60 ? 0.07 : 0))
        }
    }
}

// MARK: - Forecast card

private struct HomeForecastCard: View {
    let dailyForecasts: [DailyForecastItem]
    let isPremium: Bool
    let onUpgradeTap: () -> Void

    private let limit: Int
    private let shown: ArraySlice<DailyForecastItem>

    init(dailyForecasts: [DailyForecastItem], isPremium: Bool, onUpgradeTap: @escaping () -> Void) {
        self.dailyForecasts = dailyForecasts
        self.isPremium = isPremium
        self.onUpgradeTap = onUpgradeTap
        self.limit = isPremium ? 14 : 3
        self.shown = dailyForecasts.prefix(isPremium ? 14 : 3)
    }

    private var tempRange: ClosedRange<Double> {
        let highs = shown.map(\.highTemp)
        let lows  = shown.map(\.lowTemp)
        let lo = (lows.min() ?? 0) - 1
        let hi = (highs.max() ?? 40) + 1
        return lo...hi
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_forecast_label"), icon: "calendar")

                VStack(spacing: 2) {
                    ForEach(shown) { forecast in
                        ForecastRow(forecast: forecast, range: tempRange)
                        if forecast.id != shown.last?.id {
                            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                        }
                    }
                }

                if !isPremium && dailyForecasts.count > 3 {
                    Button {
                        HapticManager.medium()
                        onUpgradeTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill").font(.system(size: 12))
                            Text(L10n.text("home_forecast_premium_cta")).font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.28))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.28).opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(red: 1.0, green: 0.8, blue: 0.28).opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
    }
}

private struct ForecastRow: View {
    let forecast: DailyForecastItem
    let range: ClosedRange<Double>

    private let sky = Color(red: 0.4, green: 0.72, blue: 1.0)
    private let rain = Color(red: 0.35, green: 0.55, blue: 0.9)

    var body: some View {
        HStack(spacing: 10) {
            // Day name
            Text(forecast.dayName)
                .font(.system(size: 15, weight: forecast.isToday ? .semibold : .regular))
                .foregroundStyle(forecast.isToday ? .white : Color.white.opacity(0.7))
                .frame(width: 44, alignment: .leading)

            // Condition icon
            Image(systemName: forecast.conditionSymbol)
                .font(.system(size: 17))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(sky)
                .frame(width: 26)

            // Precipitation chance (if notable)
            if forecast.precipitationChance >= 0.2 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill").font(.system(size: 9))
                    Text(String(format: "%.0f%%", forecast.precipitationChance * 100)).font(.system(size: 11))
                }
                .foregroundStyle(rain.opacity(0.8))
                .frame(width: 38, alignment: .leading)
            } else {
                Color.clear.frame(width: 38)
            }

            Spacer()

            // Temp bar
            TempRangeBar(low: forecast.lowTemp, high: forecast.highTemp, range: range)
                .frame(width: 80, height: 5)

            // Low / High
            HStack(spacing: 6) {
                Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                    .foregroundStyle(Color.white.opacity(0.3))
                    .frame(width: 30, alignment: .trailing)
                Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                    .foregroundStyle(.white)
                    .frame(width: 30, alignment: .trailing)
            }
            .font(.system(size: 15, weight: .medium))
            .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}

private struct TempRangeBar: View {
    let low: Double
    let high: Double
    let range: ClosedRange<Double>

    private var span: Double { range.upperBound - range.lowerBound }

    private func fraction(_ value: Double) -> Double {
        guard span > 0 else { return 0 }
        return max(0, min(1, (value - range.lowerBound) / span))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.72, blue: 1.0), Color(red: 1.0, green: 0.6, blue: 0.2)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(8, geo.size.width * CGFloat(fraction(high) - fraction(low))))
                    .offset(x: geo.size.width * CGFloat(fraction(low)))
            }
        }
    }
}

// MARK: - Activity card

private struct HomeActivityCard: View {
    let recommendations: [ActivityRecommendation]
    private let green = Color(red: 0.3, green: 0.85, blue: 0.58)

    var body: some View {
        GlassCard(accentColor: green) {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_activity_label"), icon: "figure.run", color: green)

                VStack(spacing: 0) {
                    ForEach(recommendations.prefix(3)) { rec in
                        ActivityRow(rec: rec, color: green)
                        if rec.id != recommendations.prefix(3).last?.id {
                            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct ActivityRow: View {
    let rec: ActivityRecommendation
    let color: Color

    private var activityIcon: String {
        switch rec.activityType {
        case .running:      return "figure.run"
        case .walking:      return "figure.walk"
        case .cycling:      return "bicycle"
        case .goingOutside: return "sun.max.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: activityIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(rec.activityType.localizedTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(rec.bestWindow.shortDisplayText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            // Score gauge arc
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.white.opacity(0.07), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .frame(width: 38, height: 38)
                Circle()
                    .trim(from: 0, to: 0.75 * rec.score.displayValue / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(135))
                    .frame(width: 38, height: 38)
                Text(String(format: "%.0f", rec.score.displayValue))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Outfit card

private struct HomeOutfitCard: View {
    let outfit: OutfitRecommendation
    private let purple = Color(red: 0.75, green: 0.55, blue: 1.0)

    var body: some View {
        GlassCard(accentColor: purple) {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_outfit_label"), icon: "tshirt.fill", color: purple)

                Text(outfit.title)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)

                if !outfit.items.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(outfit.items, id: \.self) { item in
                            OutfitChip(text: item, color: purple)
                        }
                        ForEach(outfit.accessories, id: \.self) { acc in
                            OutfitChip(text: acc, color: Color(red: 1.0, green: 0.75, blue: 0.35), icon: "sparkles")
                        }
                    }
                }

                if let warning = outfit.warning {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(red: 1.0, green: 0.65, blue: 0.25))
                        Text(warning)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.orange.opacity(0.15), lineWidth: 1))
                }
            }
        }
    }
}

private struct OutfitChip: View {
    let text: String
    let color: Color
    var icon: String = "checkmark"

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Risk card

private struct HomeRiskCard: View {
    let risks: [WeatherRisk]

    var body: some View {
        GlassCard(accentColor: Color(red: 1.0, green: 0.42, blue: 0.42)) {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_risk_label"), icon: "exclamationmark.shield.fill", color: Color(red: 1.0, green: 0.42, blue: 0.42))

                VStack(spacing: 0) {
                    ForEach(risks) { risk in
                        RiskRow(risk: risk)
                        if risk.id != risks.last?.id {
                            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct RiskRow: View {
    let risk: WeatherRisk

    private var color: Color { AppTheme.color(for: risk.severity) }

    private var icon: String {
        switch risk.type {
        case .heat:        return "thermometer.sun.fill"
        case .uv:          return "sun.max.fill"
        case .rain:        return "cloud.rain.fill"
        case .wind:        return "wind"
        case .humidity:    return "humidity.fill"
        case .cold:        return "snowflake"
        case .storm:       return "cloud.bolt.rain.fill"
        case .poorComfort: return "exclamationmark.circle.fill"
        case .pollen:      return "leaf.fill"
        case .airQuality:  return "aqi.medium"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(risk.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(risk.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            // Severity dot
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.7), radius: 3)
        }
        .padding(.vertical, 10)
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

