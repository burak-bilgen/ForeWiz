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

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
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
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.text("home_title"))
                    .font(AppTypography.headline)
                Text(lastUpdatedSubtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.medium()
                showLocationPicker = true
            } label: {
                Label(viewModel.selectedLocationName, systemImage: "location.fill")
                    .labelStyle(.titleAndIcon)
                    .font(AppTypography.caption2)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            HomeLoadingView()
        case .failed(let message):
            ScreenErrorView(
                message: message,
                retryTitle: L10n.text("home_error_retry"),
                retry: viewModel.onAppear
            )
        case .loaded(let state):
            HomeLoadedScroll(
                state: state,
                isPremium: isPremium,
                onUpgradeTap: { showPaywall = true },
                refresh: { await viewModel.refresh() }
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var lastUpdatedSubtitle: String {
        if case .loaded(let state) = viewModel.state {
            return state.lastUpdatedText
        }
        return ""
    }
}

// MARK: - Loading

private struct HomeLoadingView: View {
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            LoadingCardPlaceholder(height: 220, cornerRadius: AppTheme.cardRadius)
            LoadingCardPlaceholder(height: 120, cornerRadius: AppTheme.cardRadius)
            LoadingCardPlaceholder(height: 160, cornerRadius: AppTheme.cardRadius)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.medium)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityLabel(L10n.text("home_loading"))
    }
}

// MARK: - Loaded scroll

private struct HomeLoadedScroll: View {
    let state: HomeViewState
    let isPremium: Bool
    let onUpgradeTap: () -> Void
    let refresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                CurrentWeatherHero(
                    weather: state.currentWeather,
                    recommendation: state.recommendation,
                    isUsingCached: state.isUsingCachedWeather
                )

                if let warning = state.warningMessage {
                    HomeWarningBanner(message: warning)
                }

                QuickInsightGrid(recommendation: state.recommendation)

                WeeklyForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium)

                if !isPremium {
                    AdBannerView(adUnitID: nil, isPremium: isPremium, onRemoveAdsTapped: onUpgradeTap)
                }

                if !state.recommendation.bestActivityWindows.isEmpty {
                    ActivityWindowsSection(recommendations: state.recommendation.bestActivityWindows)
                }

                OutfitCard(outfit: state.recommendation.outfit)

                if !state.recommendation.risks.isEmpty {
                    WeatherRiskSection(risks: state.recommendation.risks)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .scrollIndicators(.hidden)
        .refreshable { await refresh() }
    }
}

// MARK: - Warning banner

private struct HomeWarningBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.medium)
        .background(
            AppTheme.warning.opacity(0.10),
            in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                .stroke(AppTheme.warning.opacity(0.25), lineWidth: 0.5)
        }
    }
}

// MARK: - Current weather hero

/// Single combined hero: condition icon, big temperature, decision pill, score ring,
/// best-time chip. Sits on a tinted gradient that follows the day's outdoor decision.
private struct CurrentWeatherHero: View {
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCached: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            // Top row: condition + temperature
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if isUsingCached {
                        HeroChip(
                            text: L10n.text("weather_latest_forecast"),
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                    Text(weather.temperatureText)
                        .font(AppTypography.heroNumber)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(weather.conditionText)
                        .font(AppTypography.title3)
                    Text(weather.feelsLikeText)
                        .font(AppTypography.callout)
                        .foregroundStyle(.white.opacity(0.78))
                }
                Spacer(minLength: 0)
                Image(systemName: weather.symbolName)
                    .font(.system(size: 64, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .accessibilityHidden(true)
            }

            Divider()
                .overlay(.white.opacity(0.25))

            // Bottom row: decision summary + score ring
            HStack(alignment: .center, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(recommendation.outdoorDecision.localizedTitle)
                        .font(AppTypography.title2)
                    Text(recommendation.summaryText)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let bestWindow = recommendation.bestOutdoorWindow {
                        HeroChip(
                            text: bestWindow.shortDisplayText,
                            systemImage: "clock.fill"
                        )
                    }
                }
                Spacer(minLength: 0)
                HeroScoreRing(score: recommendation.outdoorScore)
            }
        }
        .foregroundStyle(.white)
        .padding(AppSpacing.large)
        .background(
            AppTheme.heroGradient(for: recommendation.outdoorDecision, colorScheme: colorScheme),
            in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.30 : 0.10), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

private struct HeroChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.18), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous).stroke(.white.opacity(0.25), lineWidth: 0.5)
            }
    }
}

/// Inline white-on-tint score ring tuned for the hero card.
private struct HeroScoreRing: View {
    let score: WeatherScore
    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 7)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(score.displayValue, format: .number.precision(.fractionLength(1)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("/10")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(width: 76, height: 76)
        .onAppear { animate() }
        .onChange(of: score) { _, _ in animate() }
    }

    private func animate() {
        let target = score.displayValue / 10
        if reduceMotion {
            progress = target
        } else {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85)) {
                progress = target
            }
        }
    }
}
