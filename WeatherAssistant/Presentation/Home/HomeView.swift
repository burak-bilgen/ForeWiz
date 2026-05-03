import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                content
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                viewModel.onAppear()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Öneri hazırlanıyor")
        case .failed(let message):
            ScreenErrorView(message: message, retryTitle: "Tekrar dene", retry: viewModel.onAppear)
        case .loaded(let state):
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HomeHeaderView(
                        lastUpdatedText: state.lastUpdatedText,
                        isUsingCachedWeather: state.isUsingCachedWeather
                    )
                    CurrentWeatherHeroCard(
                        weather: state.currentWeather,
                        recommendation: state.recommendation,
                        isUsingCachedWeather: state.isUsingCachedWeather
                    )
                    if let warningMessage = state.warningMessage {
                        StatusBanner(message: warningMessage, systemImage: "wifi.exclamationmark")
                    }
                    DailyDecisionCard(recommendation: state.recommendation)
                    QuickInsightGrid(recommendation: state.recommendation)
                    ActivityWindowsSection(recommendations: state.recommendation.bestActivityWindows)
                    OutfitCard(outfit: state.recommendation.outfit)
                    AvoidHoursCard(avoidWindows: state.recommendation.avoidWindows)
                    WeatherRiskSection(risks: state.recommendation.risks)
                    if let attribution = state.attribution {
                        Text(attribution)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.horizontal, AppSpacing.xSmall)
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
        }
    }
}

private struct HomeHeaderView: View {
    let lastUpdatedText: String
    let isUsingCachedWeather: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("WeatherAssistant")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.small) {
                    Label("Bugünün hava kararı", systemImage: "sparkles")
                    Text("Güncellendi \(lastUpdatedText)")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.small)

            Label(isUsingCachedWeather ? "Kayıtlı" : "Canlı", systemImage: isUsingCachedWeather ? "clock.fill" : "location.fill")
                .font(AppTypography.caption.weight(.semibold))
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(
                    isUsingCachedWeather ? AppTheme.warning.opacity(0.14) : AppTheme.success.opacity(0.14),
                    in: Capsule()
                )
                .foregroundStyle(isUsingCachedWeather ? AppTheme.warning : AppTheme.success)
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
                    Label(isUsingCachedWeather ? "Kayıtlı tahmin" : "Canlı tahmin", systemImage: isUsingCachedWeather ? "clock.fill" : "location.fill")
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
                    title: "Dışarı",
                    value: recommendation.outdoorScore.displayValue.formatted(.number.precision(.fractionLength(1))) + "/10"
                )
                WeatherHeroMetric(
                    icon: "clock.fill",
                    title: "En iyi saat",
                    value: recommendation.bestOutdoorWindow?.shortDisplayText ?? "Belirsiz"
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
