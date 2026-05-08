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
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                content
            }
            .navigationBarTitleDisplayMode(.large)
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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                HapticManager.light()
                showLocationPicker = true
            } label: {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
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
            HomeLoadedContent(
                state: state,
                isPremium: isPremium,
                onUpgradeTap: { showPaywall = true },
                refresh: { await viewModel.refresh() }
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
        }
    }
}

// MARK: - Loading

private struct HomeLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text(L10n.text("home_loading"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(L10n.text("home_loading"))
    }
}

// MARK: - Loaded content

private struct HomeLoadedContent: View {
    let state: HomeViewState
    let isPremium: Bool
    let onUpgradeTap: () -> Void
    let refresh: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ModernWeatherHero(
                    weather: state.currentWeather,
                    recommendation: state.recommendation,
                    isUsingCached: state.isUsingCachedWeather
                )

                if let warning = state.warningMessage {
                    ModernWarningBanner(message: warning)
                }

                ModernInsightGrid(recommendation: state.recommendation)

                ModernForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium, onUpgradeTap: onUpgradeTap)

                if !isPremium {
                    AdBannerView(adUnitID: nil, isPremium: isPremium, onRemoveAdsTapped: onUpgradeTap)
                }

                if !state.recommendation.bestActivityWindows.isEmpty {
                    ModernActivitySection(recommendations: state.recommendation.bestActivityWindows)
                }

                ModernHourlyForecastCard(hourlyScores: hourlyScores(for: state.recommendation))

                ModernOutfitCard(outfit: state.recommendation.outfit)

                if !state.recommendation.risks.isEmpty {
                    ModernRiskSection(risks: state.recommendation.risks)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .refreshable { await refresh() }
    }
}

// MARK: - Warning banner

private struct ModernWarningBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: - Modern insight grid

private struct ModernInsightGrid: View {
    let recommendation: DailyRecommendation

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ModernInsightCard(
                icon: "thermometer",
                title: "Karar",
                value: recommendation.outdoorDecision.localizedTitle
            )
            ModernInsightCard(
                icon: "star.fill",
                title: "Skor",
                value: String(format: "%.1f", recommendation.outdoorScore.displayValue)
            )
        }
    }
}

private struct ModernInsightCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

// MARK: - Modern weather hero

private struct ModernWeatherHero: View {
    let weather: HomeCurrentWeatherViewState
    let recommendation: DailyRecommendation
    let isUsingCached: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.temperatureText)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(weather.conditionText)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(weather.feelsLikeText)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: weather.symbolName)
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.outdoorDecision.localizedTitle)
                        .font(.headline)
                    Text(recommendation.summaryText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if let bestWindow = recommendation.bestOutdoorWindow {
                        Text(bestWindow.shortDisplayText)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", recommendation.outdoorScore.displayValue))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Skor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Modern forecast card

private struct ModernForecastCard: View {
    let dailyForecasts: [DailyForecastItem]
    let isPremium: Bool
    let onUpgradeTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hava Tahmini")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(dailyForecasts.prefix(isPremium ? 14 : 3)) { forecast in
                    ModernForecastRow(forecast: forecast)
                }

                if !isPremium && dailyForecasts.count > 3 {
                    Button {
                        HapticManager.medium()
                        onUpgradeTap()
                    } label: {
                        Text("14 günlük tahmini görmek için Premium'a geç")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernForecastRow: View {
    let forecast: DailyForecastItem

    var body: some View {
        HStack {
            Text(forecast.dayName)
                .font(.subheadline)
                .frame(width: 60, alignment: .leading)
            Spacer()
            Image(systemName: forecast.conditionSymbol)
                .frame(width: 30)
            Spacer()
            Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
            Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(forecast.dayName), yüksek \(forecast.highTemp.formatted(.number.precision(.fractionLength(0)))) derece, düşük \(forecast.lowTemp.formatted(.number.precision(.fractionLength(0)))) derece")
    }
}

// MARK: - Modern activity section

private struct ModernActivitySection: View {
    let recommendations: [ActivityRecommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En İyi Zamanlar")
                .font(.headline)

            if recommendations.isEmpty {
                Text("Uygun zaman bulunamadı")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(recommendations.prefix(3)) { recommendation in
                        ModernActivityRow(recommendation: recommendation)
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernActivityRow: View {
    let recommendation: ActivityRecommendation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.activityType.localizedTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.bestWindow.shortDisplayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.1f", recommendation.score.displayValue))
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recommendation.activityType.localizedTitle), skor \(String(format: "%.1f", recommendation.score.displayValue)), en iyi zaman \(recommendation.bestWindow.shortDisplayText)")
    }
}

// MARK: - Modern outfit card

private struct ModernOutfitCard: View {
    let outfit: OutfitRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kıyafet Önerisi")
                .font(.headline)

            Text(outfit.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let warning = outfit.warning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 20)
                    Text(warning)
                        .font(.subheadline)
                }
            }

            if !outfit.items.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(outfit.items, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            Text(item)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Modern risk section

private struct ModernRiskSection: View {
    let risks: [WeatherRisk]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riskler")
                .font(.headline)

            if risks.isEmpty {
                Text("Risk yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(risks) { risk in
                        ModernRiskRow(risk: risk)
                    }
                }
            }
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

private struct ModernHourlyForecastCard: View {
    let hourlyScores: [WeatherScore]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saatlik Tahmin")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(hourlyScores.prefix(24).enumerated()), id: \.offset) { index, score in
                        VStack(spacing: 4) {
                            Capsule()
                                .fill(scoreColor(for: score))
                                .frame(width: 8, height: max(8, CGFloat(score.rawValue)))
                            Text(hourLabel(for: index))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 40)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func scoreColor(for score: WeatherScore) -> Color {
        switch score.rawValue {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private func hourLabel(for index: Int) -> String {
        var hour = Calendar.current.component(.hour, from: Date()) + index
        if hour >= 24 { hour -= 24 }
        return "\(hour):00"
    }
}

private func hourlyScores(for recommendation: DailyRecommendation) -> [WeatherScore] {
    let currentHour = Calendar.current.component(.hour, from: Date())
    var scores: [WeatherScore] = []

    for _ in currentHour..<min(currentHour + 12, 24) {
        let score = recommendation.outdoorScore
        scores.append(score)
    }

    return scores
}

private struct ModernRiskRow: View {
    let risk: WeatherRisk

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: riskIcon(for: risk.type))
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(risk.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(risk.title), şiddet \(severityLabel(for: risk.severity))")
    }

    private var color: Color {
        switch risk.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .extreme: return .purple
        }
    }

    private func riskIcon(for type: WeatherRiskType) -> String {
        switch type {
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

    private func severityLabel(for severity: RiskLevel) -> String {
        switch severity {
        case .low: return "düşük"
        case .medium: return "orta"
        case .high: return "yüksek"
        case .extreme: return "aşırı"
        }
    }
}
