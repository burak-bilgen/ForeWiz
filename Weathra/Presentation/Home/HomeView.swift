import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var savedLocations: [SavedLocation]
    @Binding var selectedLocationID: String
    @State private var selectedAttribution: WeatherAttributionInfo?
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
                    .animation(.easeInOut(duration: 0.35), value: viewModel.state)
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.onAppear()
            }
            .sheet(item: $selectedAttribution) { attribution in
                WeatherAttributionDetailView(attribution: attribution)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    savedLocations: $savedLocations,
                    selectedLocationID: $selectedLocationID,
                    onSelect: { location in
                        Task {
                            await viewModel.changeLocation(to: location)
                        }
                    }
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store)
            }
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
            VStack(spacing: AppSpacing.medium) {
                ProgressView()
                    .controlSize(.large)
                Text(String(localized: "home_loading"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        case .failed(let message):
            ScreenErrorView(message: message, retryTitle: String(localized: "home_error_retry"), retry: viewModel.onAppear)
                .transition(.opacity)
        case .loaded(let state):
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HomeHeaderView(
                        lastUpdatedText: state.lastUpdatedText,
                        isUsingCachedWeather: state.isUsingCachedWeather,
                        locationName: viewModel.selectedLocationName,
                        onLocationTap: { showLocationPicker = true }
                    )
                    CurrentWeatherHeroCard(
                        weather: state.currentWeather,
                        recommendation: state.recommendation,
                        isUsingCachedWeather: state.isUsingCachedWeather
                    )
                    if let warningMessage = state.warningMessage {
                        StatusBanner(message: warningMessage, systemImage: "wifi.exclamationmark")
                    }
                    NavigationLink(destination: RecommendationDetailView(recommendation: state.recommendation)) {
                        DailyDecisionCard(recommendation: state.recommendation)
                    }
                    .buttonStyle(.plain)
                    QuickInsightGrid(recommendation: state.recommendation)
                    WeeklyForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium)
                    if !isPremium {
                        AdBannerView(adUnitID: nil)
                            .onTapGesture { showPaywall = true }
                    }
                    ActivityWindowsSection(recommendations: state.recommendation.bestActivityWindows)
                    OutfitCard(outfit: state.recommendation.outfit)
                    AvoidHoursCard(avoidWindows: state.recommendation.avoidWindows)
                    WeatherRiskSection(risks: state.recommendation.risks)
                    if let attribution = state.attribution {
                        WeatherAttributionFooter(attribution: attribution) {
                            selectedAttribution = attribution
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.medium)
                .padding(.bottom, AppSpacing.xLarge)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .transition(.opacity)
        }
    }
}

private struct HomeHeaderView: View {
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool
    let locationName: String
    let onLocationTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(String(localized: "home_title"))
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.small) {
                    Label(String(localized: "home_daily_summary"), systemImage: "sparkles")
                        Text(String(localized: "home_updated") + " " + lastUpdatedText)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.small)

            VStack(alignment: .trailing, spacing: AppSpacing.xSmall) {
                Button(action: onLocationTap) {
                    HStack(spacing: AppSpacing.xSmall) {
                        Image(systemName: "location.fill")
                            .font(.caption2.weight(.semibold))
                        Text(locationName)
                            .font(AppTypography.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(AppTheme.elevatedSurface, in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)

                Label(isUsingCachedWeather ? String(localized: "home_last_saved") : String(localized: "home_live"), systemImage: isUsingCachedWeather ? "clock.fill" : "location.fill")
                    .symbolEffect(.pulse, isActive: !isUsingCachedWeather)
                    .font(AppTypography.caption.weight(.semibold))
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
                    .background(
                        isUsingCachedWeather ? AppTheme.warning.opacity(0.14) : AppTheme.success.opacity(0.14),
                        in: Capsule()
                    )
                    .foregroundStyle(isUsingCachedWeather ? AppTheme.warning : AppTheme.success)
            }
        }
        .padding(.horizontal, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}

private struct CurrentWeatherHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCachedWeather: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label(isUsingCachedWeather ? String(localized: "weather_latest_forecast") : String(localized: "weather_live_forecast"), systemImage: isUsingCachedWeather ? "clock.fill" : "location.fill")
                        .font(AppTypography.caption.weight(.semibold))
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.xSmall)
                        .background(.white.opacity(0.18), in: Capsule())

                    Text(weather.temperatureText)
                        .font(.system(size: 68, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(weather.feelsLikeText)
                        .font(AppTypography.headline)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: AppSpacing.medium)

                VStack(alignment: .trailing, spacing: AppSpacing.small) {
                    Image(systemName: weather.symbolName)
                        .font(.system(size: 64, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 8)

                    Text(weather.conditionText)
                        .font(AppTypography.title3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            HStack(spacing: AppSpacing.small) {
                 WeatherHeroMetric(
                     icon: "figure.walk",
                     title: String(localized: "widget_outdoor_score"),
                     value: recommendation.outdoorScore.displayValue.formatted(.number.precision(.fractionLength(1))) + "/10"
                 )
                 WeatherHeroMetric(
                     icon: "clock.fill",
                     title: String(localized: "widget_best_time"),
                     value: recommendation.bestOutdoorWindow?.shortDisplayText ?? String(localized: "forecast_no_best_window")
                 )
            }
        }
        .foregroundStyle(.white)
        .padding(AppSpacing.large)
        .background(AppTheme.weatherGradient(for: colorScheme), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 18, y: -28)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: AppTheme.accent.opacity(0.22), radius: 26, y: 14)
        .accessibilityElement(children: .combine)
    }
}

private struct WeatherHeroMetric: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 28, height: 28)
                .background(.white.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.76))
                Text(value)
                    .font(AppTypography.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.small)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }
}

private struct StatusBanner: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.warning)

            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.warning.opacity(0.13), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius))
    }
}

private struct WeatherAttributionFooter: View {
    let attribution: WeatherAttributionInfo
    let showDetails: () -> Void

    var body: some View {
        Button(action: showDetails) {
            HStack(spacing: AppSpacing.xSmall) {
                Image(systemName: "apple.logo")
                    .font(.caption2.weight(.semibold))

                Text(String(localized: "weather_data_provided_by") + " " + serviceName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Image(systemName: "info.circle")
                    .font(.caption2.weight(.semibold))
            }
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(AppTheme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, AppSpacing.xSmall)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "weather_data_provided_by") + " " + serviceName)
    }

    private var serviceName: String {
        attribution.serviceName.isEmpty ? "Apple Weather" : attribution.serviceName
    }
}

private struct WeatherAttributionDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let attribution: WeatherAttributionInfo

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(String(localized: "about_legal"))
                            .font(AppTypography.title)
                            .foregroundStyle(AppTheme.ink)

                        Text(String(localized: "about_legal_desc") + " " + serviceName)
                            .font(AppTypography.body)
                            .foregroundStyle(AppTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let legalAttributionText = attribution.legalAttributionText,
                       legalAttributionText.isEmpty == false {
                        Text(legalAttributionText)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let legalPageURL {
                        Link(destination: legalPageURL) {
                            Label(String(localized: "about_apple_weather_legal"), systemImage: "arrow.up.forward.square")
                                .font(AppTypography.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
                .padding(AppSpacing.large)
            }
            .background(AppBackground())
            .navigationTitle(String(localized: "about_legal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "about_done")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var serviceName: String {
        attribution.serviceName.isEmpty ? "Apple Weather" : attribution.serviceName
    }

    private var legalPageURL: URL? {
        guard let legalPageURLString = attribution.legalPageURLString else {
            return nil
        }

        return URL(string: legalPageURLString)
    }
}
