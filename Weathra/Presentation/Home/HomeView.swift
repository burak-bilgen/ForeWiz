import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    @State private var showLocationPicker = false
    @State private var showPaywall = false
    let isPremium: Bool
    let store: StoreKitSubscriptionManager
    let onRecommendationLoaded: (DailyRecommendation) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                content
                    .animation(.easeInOut(duration: 0.3), value: viewModel.state)
            }
            .navigationBarTitleDisplayMode(.inline)
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
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case .failed(let message):
            ScreenErrorView(message: message, retryTitle: L10n.text("home_error_retry"), retry: viewModel.onAppear)
        case .loaded(let state):
            ScrollView {
                LazyVStack(spacing: 20) {
                    HomeHeader(
                        lastUpdatedText: state.lastUpdatedText,
                        isUsingCached: state.isUsingCachedWeather,
                        locationName: viewModel.selectedLocationName,
                        onLocationTap: { showLocationPicker = true }
                    )

                    CurrentWeatherHero(
                        weather: state.currentWeather,
                        recommendation: state.recommendation,
                        isUsingCached: state.isUsingCachedWeather
                    )

                    DecisionCard(recommendation: state.recommendation)

                    QuickInsightGrid(recommendation: state.recommendation)

                    WeeklyForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium)

                    if !isPremium {
                        AdBannerView(adUnitID: nil).onTapGesture { showPaywall = true }
                    }

                    ActivityWindowsSection(recommendations: state.recommendation.bestActivityWindows)

                    OutfitCard(outfit: state.recommendation.outfit)

                    if !state.recommendation.risks.isEmpty {
                        WeatherRiskSection(risks: state.recommendation.risks)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(L10n.text("home_loading"))
                .font(AppTypography.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Home Header
private struct HomeHeader: View {
    let lastUpdatedText: String
    let isUsingCached: Bool
    let locationName: String
    let onLocationTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "home_title"))
                    .font(AppTypography.title)

                HStack(spacing: 6) {
                    Text(String(localized: "home_daily_summary"))
                    Text("-").foregroundStyle(.secondary)
                    Text(lastUpdatedText)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Button(action: onLocationTap) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(locationName)
                        .font(AppTypography.caption2)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
}

// MARK: - Current Weather Hero
private struct CurrentWeatherHero: View {
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCached: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isUsingCached ? L10n.text("weather_latest_forecast") : L10n.text("home_live"))
                        .font(AppTypography.caption2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.15), in: Capsule())

                    Text(weather.temperatureText)
                        .font(.system(size: 60, weight: .bold, design: .rounded))

                    Text(weather.feelsLikeText)
                        .font(AppTypography.body)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: weather.symbolName)
                        .font(.system(size: 50, weight: .medium))
                        .symbolRenderingMode(.hierarchical)

                    Text(weather.conditionText)
                        .font(AppTypography.callout)
                }
            }

            HStack(spacing: 16) {
                HeroMetric(icon: "figure.walk", title: L10n.text("home_score"), value: "\(recommendation.outdoorScore.displayValue)/10")
                HeroMetric(icon: "clock.fill", title: L10n.text("home_best_time"), value: recommendation.bestOutdoorWindow?.shortDisplayText ?? "-")
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .background(AppTheme.weatherGradient(for: .light), in: RoundedRectangle(cornerRadius: 28))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 100, weight: .bold))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: 20, y: -30)
                .accessibilityHidden(true)
        }
    }
}

private struct HeroMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption2)
                Text(value).font(AppTypography.caption2).fontWeight(.semibold)
            }
        }
        .padding(10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Decision Card
private struct DecisionCard: View {
    let recommendation: DailyRecommendation

    var body: some View {
        HStack(spacing: 16) {
            DecisionPill(decision: recommendation.outdoorDecision)

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.outdoorDecision.localizedTitle)
                    .font(AppTypography.title2)

                Text(recommendation.summaryText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            ScoreRingView(score: recommendation.outdoorScore, size: 60)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct DecisionPill: View {
    let decision: OutdoorDecision

    var body: some View {
        Text(decision.localizedTitle)
            .font(AppTypography.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.color(for: decision).opacity(0.15), in: Capsule())
            .foregroundStyle(AppTheme.color(for: decision))
    }
}