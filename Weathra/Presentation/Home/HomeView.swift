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
        if case .loaded(let state) = viewModel.state {
            return state.currentWeather.symbolName
        }
        return "cloud.fill"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackground(symbolName: currentSymbol)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.0), value: currentSymbol)
                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { viewModel.onAppear() }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in
                        Task { await viewModel.changeLocation(to: location) }
                    }
                )
            }
            .sheet(isPresented: $showPaywall) { PaywallView(store: store) }
            .onChange(of: viewModel.state) { _, newState in
                if case .loaded(let state) = newState {
                    onRecommendationLoaded(state.recommendation)
                }
            }
        }
        .dynamicTypeSize(.large ... .xxxLarge)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("Weathra")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.light()
                showLocationPicker = true
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView()
                .transition(.opacity)
        case .failed(let message):
            HomeErrorView(
                message: message,
                retry: viewModel.onAppear
            )
            .transition(.opacity)
        case .loaded(let state):
            HomeLoadedContent(
                state: state,
                isPremium: isPremium,
                onUpgradeTap: { showPaywall = true },
                refresh: { await viewModel.refresh() }
            )
            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        }
    }
}

// MARK: - Background

private struct HomeBackground: View {
    var symbolName: String = "cloud.fill"

    private var accentColor: Color {
        switch symbolName {
        case let s where s.contains("sun"): return Color(red: 1.0, green: 0.65, blue: 0.2)
        case let s where s.contains("rain") || s.contains("drizzle"): return Color(red: 0.3, green: 0.55, blue: 0.9)
        case let s where s.contains("snow") || s.contains("sleet"): return Color(red: 0.7, green: 0.85, blue: 1.0)
        case let s where s.contains("storm") || s.contains("thunder"): return Color(red: 0.55, green: 0.3, blue: 0.9)
        case let s where s.contains("fog") || s.contains("mist"): return Color(red: 0.6, green: 0.65, blue: 0.75)
        default: return Color(red: 0.3, green: 0.5, blue: 0.9)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.16),
                    Color(red: 0.05, green: 0.10, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(accentColor.opacity(0.13))
                .frame(width: 380)
                .blur(radius: 75)
                .offset(x: -90, y: -190)
                .animation(.easeInOut(duration: 1.2), value: symbolName)
            Circle()
                .fill(accentColor.opacity(0.07))
                .frame(width: 280)
                .blur(radius: 60)
                .offset(x: 140, y: 230)
                .animation(.easeInOut(duration: 1.2), value: symbolName)
        }
    }
}

// MARK: - Loading

private struct HomeLoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            }
            Text(L10n.text("home_loading"))
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pulse = true }
    }
}

// MARK: - Error

private struct HomeErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "cloud.slash.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .symbolRenderingMode(.hierarchical)
            }
            VStack(spacing: 8) {
                Text(L10n.text("home_loading_error_title"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            Button {
                HapticManager.light()
                retry()
            } label: {
                Text(L10n.text("home_error_retry"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15), in: Capsule())
            }
        }
        .padding(40)
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
            VStack(spacing: 20) {
                HomeHeroCard(
                    weather: state.currentWeather,
                    recommendation: state.recommendation,
                    isUsingCached: state.isUsingCachedWeather
                )
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05), value: appeared)

                if let warning = state.warningMessage {
                    HomeWarningBanner(message: warning)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.10), value: appeared)
                }

                HomeInsightRow(recommendation: state.recommendation)
                    .offset(y: appeared ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)

                HomeForecastCard(
                    dailyForecasts: state.dailyForecasts,
                    isPremium: isPremium,
                    onUpgradeTap: onUpgradeTap
                )
                .offset(y: appeared ? 0 : 24)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.20), value: appeared)

                if !isPremium {
                    HomeAdBanner(onUpgradeTap: onUpgradeTap)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.23), value: appeared)
                }

                if !state.recommendation.bestActivityWindows.isEmpty {
                    HomeActivityCard(recommendations: state.recommendation.bestActivityWindows)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.26), value: appeared)
                }

                HomeHourlyCard(hourlyScores: state.hourlyScores)
                    .offset(y: appeared ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.30), value: appeared)

                HomeOutfitCard(outfit: state.recommendation.outfit)
                    .offset(y: appeared ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.34), value: appeared)

                if !state.recommendation.risks.isEmpty {
                    HomeRiskCard(risks: state.recommendation.risks)
                        .offset(y: appeared ? 0 : 24)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.38), value: appeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .refreshable { await refresh() }
        .onAppear { appeared = true }
    }
}

// MARK: - Shared card background

private struct DarkCard<Content: View>: View {
    let accentColor: Color
    let content: Content

    init(accentColor: Color = .blue, @ViewBuilder content: () -> Content) {
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
    }
}

private struct SectionLabel: View {
    let title: String
    let icon: String
    var color: Color = Color(red: 0.4, green: 0.7, blue: 1.0)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

// MARK: - Hero card

private struct HomeHeroCard: View {
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCached: Bool

    var body: some View {
        DarkCard(accentColor: .blue) {
            VStack(spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(weather.temperatureText)
                            .font(.system(size: 68, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(weather.conditionText)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.75))
                        Text(weather.feelsLikeText)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Image(systemName: weather.symbolName)
                            .font(.system(size: 56))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color(red: 0.55, green: 0.8, blue: 1.0))
                        if isUsingCached {
                            Text(L10n.text("home_cached_label"))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white.opacity(0.35))
                        }
                    }
                }

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recommendation.outdoorDecision.localizedTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(recommendation.summaryText)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(2)
                        if let bestWindow = recommendation.bestOutdoorWindow {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                Text(bestWindow.shortDisplayText)
                                    .font(.system(size: 13))
                            }
                            .foregroundStyle(Color(red: 0.4, green: 0.8, blue: 1.0))
                        }
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f", recommendation.outdoorScore.displayValue))
                            .font(.system(size: 38, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(L10n.text("home_score_label"))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
            }
        }
    }
}

// MARK: - Warning banner

private struct HomeWarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(16)
        .background(Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Insight row

private struct HomeInsightRow: View {
    let recommendation: DailyRecommendation

    var body: some View {
        HStack(spacing: 12) {
            HomeInsightPill(
                icon: "checkmark.seal.fill",
                label: L10n.text("home_decision_label"),
                value: recommendation.outdoorDecision.localizedTitle,
                color: Color(red: 0.4, green: 0.85, blue: 0.6)
            )
            HomeInsightPill(
                icon: "gauge.medium",
                label: L10n.text("home_score_label"),
                value: String(format: "%.0f/100", recommendation.outdoorScore.displayValue),
                color: Color(red: 0.4, green: 0.7, blue: 1.0)
            )
        }
    }
}

private struct HomeInsightPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Forecast card

private struct HomeForecastCard: View {
    let dailyForecasts: [DailyForecastItem]
    let isPremium: Bool
    let onUpgradeTap: () -> Void

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(title: L10n.text("home_forecast_label"), icon: "calendar")

                VStack(spacing: 4) {
                    ForEach(dailyForecasts.prefix(isPremium ? 14 : 3)) { forecast in
                        HomeForecastRow(forecast: forecast)
                        if forecast.id != dailyForecasts.prefix(isPremium ? 14 : 3).last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                        }
                    }
                }

                if !isPremium && dailyForecasts.count > 3 {
                    Button {
                        HapticManager.medium()
                        onUpgradeTap()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 12))
                            Text(L10n.text("home_forecast_premium_cta"))
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.3))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
    }
}

private struct HomeForecastRow: View {
    let forecast: DailyForecastItem

    var body: some View {
        HStack {
            Text(forecast.dayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 68, alignment: .leading)
            Image(systemName: forecast.conditionSymbol)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color(red: 0.55, green: 0.8, blue: 1.0))
                .frame(width: 28)
            Spacer()
            Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .frame(width: 38, alignment: .trailing)
            Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.35))
                .monospacedDigit()
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Ad banner

private struct HomeAdBanner: View {
    let onUpgradeTap: () -> Void

    var body: some View {
        Button(action: onUpgradeTap) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.3))
                Text(L10n.text("ad_label_text"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
                Spacer()
                Text(L10n.text("premium_upgrade"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.3))
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity card

private struct HomeActivityCard: View {
    let recommendations: [ActivityRecommendation]

    var body: some View {
        DarkCard(accentColor: Color(red: 0.4, green: 0.85, blue: 0.6)) {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(
                    title: L10n.text("home_activity_label"),
                    icon: "figure.run",
                    color: Color(red: 0.4, green: 0.85, blue: 0.6)
                )
                VStack(spacing: 4) {
                    ForEach(recommendations.prefix(3)) { rec in
                        HomeActivityRow(recommendation: rec)
                        if rec.id != recommendations.prefix(3).last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct HomeActivityRow: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.activityType.localizedTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(recommendation.bestWindow.shortDisplayText)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            Spacer()
            Text(String(format: "%.0f", recommendation.score.displayValue))
                .font(.system(size: 22, weight: .thin, design: .rounded))
                .foregroundStyle(Color(red: 0.4, green: 0.85, blue: 0.6))
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Hourly card

private struct HomeHourlyCard: View {
    let hourlyScores: [HourlyScoreItem]

    var body: some View {
        DarkCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(title: L10n.text("home_hourly_label"), icon: "clock.fill")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(hourlyScores.prefix(12), id: \.hour) { item in
                            VStack(spacing: 6) {
                                Capsule()
                                    .fill(scoreColor(for: item.score))
                                    .frame(width: 8, height: max(12, CGFloat(item.score) * 0.65))
                                Text(String(format: "%02d", item.hour))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.white.opacity(0.35))
                            }
                            .frame(width: 36, alignment: .bottom)
                        }
                    }
                    .padding(.bottom, 2)
                }
                .frame(height: 90)
            }
        }
    }

    private func scoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return Color(red: 0.35, green: 0.85, blue: 0.6)
        case 60..<80: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case 40..<60: return Color(red: 1.0, green: 0.7, blue: 0.3)
        default: return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }
}

// MARK: - Outfit card

private struct HomeOutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        DarkCard(accentColor: Color(red: 0.8, green: 0.65, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(
                    title: L10n.text("home_outfit_label"),
                    icon: "tshirt.fill",
                    color: Color(red: 0.8, green: 0.65, blue: 1.0)
                )

                Text(outfit.title)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.6))

                if let warning = outfit.warning {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.7, blue: 0.3))
                        Text(warning)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if !outfit.items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(outfit.items, id: \.self) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(red: 0.8, green: 0.65, blue: 1.0))
                                Text(item)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.75))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Risk card

private struct HomeRiskCard: View {
    let risks: [WeatherRisk]

    var body: some View {
        DarkCard(accentColor: Color(red: 1.0, green: 0.5, blue: 0.5)) {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(
                    title: L10n.text("home_risk_label"),
                    icon: "exclamationmark.shield.fill",
                    color: Color(red: 1.0, green: 0.5, blue: 0.5)
                )
                VStack(spacing: 4) {
                    ForEach(risks) { risk in
                        HomeRiskRow(risk: risk)
                        if risk.id != risks.last?.id {
                            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                        }
                    }
                }
            }
        }
    }
}

private struct HomeRiskRow: View {
    let risk: WeatherRisk

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(severityColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: riskIcon)
                    .font(.system(size: 15))
                    .foregroundStyle(severityColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(risk.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(risk.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var severityColor: Color {
        switch risk.severity {
        case .low: return Color(red: 0.35, green: 0.85, blue: 0.6)
        case .medium: return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .high: return Color(red: 1.0, green: 0.45, blue: 0.45)
        case .extreme: return Color(red: 0.75, green: 0.35, blue: 1.0)
        }
    }

    private var riskIcon: String {
        switch risk.type {
        case .heat: return "thermometer.sun.fill"
        case .uv: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .humidity: return "humidity.fill"
        case .cold: return "snowflake"
        case .storm: return "cloud.bolt.rain.fill"
        case .poorComfort: return "exclamationmark.circle.fill"
        case .pollen: return "leaf.fill"
        case .airQuality: return "aqi.medium"
        }
    }
}

