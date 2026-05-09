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
            .padding(.horizontal, 16)
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
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.12), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
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
                HomeStatusBar(
                    updatedText: state.lastUpdatedText,
                    isUsingCached: state.isUsingCachedWeather,
                    refresh: refresh
                )
                .cardEntrance(appeared: appeared, delay: 0.01)

                HomeAssistantCard(assistant: state.assistant)
                    .cardEntrance(appeared: appeared, delay: 0.02)

                HomePlanCard(plan: state.plan)
                    .cardEntrance(appeared: appeared, delay: 0.05)

                HomeHeroCard(weather: state.currentWeather, recommendation: state.recommendation, isUsingCached: state.isUsingCachedWeather)
                    .cardEntrance(appeared: appeared, delay: 0.08)

                HomeEnvironmentCard(environment: state.environment)
                    .cardEntrance(appeared: appeared, delay: 0.10)

                if !state.recommendation.risks.isEmpty {
                    HomeRiskCard(risks: state.recommendation.risks)
                        .cardEntrance(appeared: appeared, delay: 0.14)
                }

                if let warning = state.warningMessage {
                    HomeWarningBanner(message: warning).cardEntrance(appeared: appeared, delay: 0.16)
                }

                HomeHourlyCard(hourlyScores: state.hourlyScores, recommendation: state.recommendation)
                    .cardEntrance(appeared: appeared, delay: 0.18)

                HomeForecastCard(dailyForecasts: state.dailyForecasts, isPremium: isPremium, onUpgradeTap: onUpgradeTap)
                    .cardEntrance(appeared: appeared, delay: 0.22)

                if !isPremium {
                    AdBannerView(isPremium: false, onRemoveAdsTapped: onUpgradeTap)
                        .cardEntrance(appeared: appeared, delay: 0.24)
                }

                HomeQuickTipsCard(recommendation: state.recommendation, currentWeather: state.currentWeather)
                    .cardEntrance(appeared: appeared, delay: 0.26)

                if !state.recommendation.bestActivityWindows.isEmpty {
                    HomeActivityCard(recommendations: state.recommendation.bestActivityWindows)
                        .cardEntrance(appeared: appeared, delay: 0.30)
                }

                HomeOutfitCard(outfit: state.recommendation.outfit)
                    .cardEntrance(appeared: appeared, delay: 0.34)

                if let attribution = state.attribution {
                    HomeAttributionView(info: attribution)
                        .cardEntrance(appeared: appeared, delay: 0.38)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 12)
        .refreshable { await refresh() }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { appeared = true }
        }
    }
}

// MARK: - Assistant card

private struct HomeStatusBar: View {
    let updatedText: String
    let isUsingCached: Bool
    let refresh: () async -> Void

    private let liveColor = Color(red: 0.3, green: 0.85, blue: 0.58)
    private let cachedColor = Color(red: 1.0, green: 0.7, blue: 0.3)

    var body: some View {
        HStack(spacing: 10) {
            statusPill
            updatedPill
            Spacer(minLength: 6)
            Button {
                HapticManager.light()
                Task { await refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("home_error_retry"))
        }
        .padding(.horizontal, 2)
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isUsingCached ? cachedColor : liveColor)
                .frame(width: 7, height: 7)
                .shadow(color: (isUsingCached ? cachedColor : liveColor).opacity(0.8), radius: 4)
            Text(isUsingCached ? L10n.text("home_cached_label") : L10n.text("home_live"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.68))
                .lineLimit(1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var updatedPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 11, weight: .semibold))
            Text(updatedText)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(Color.white.opacity(0.48))
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.045), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

private struct HomePlanCard: View {
    let plan: HomePlanViewState

    private let blue = Color(red: 0.4, green: 0.72, blue: 1.0)

    var body: some View {
        GlassCard(accentColor: blue) {
            VStack(alignment: .leading, spacing: 14) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        CardSectionHeader(title: plan.title, icon: "checkmark.circle.fill", color: blue)
                        Spacer(minLength: 10)
                        Text(plan.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        CardSectionHeader(title: plan.title, icon: "checkmark.circle.fill", color: blue)
                        Text(plan.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(plan.items) { item in
                        PlanItemRow(item: item)
                        if item.id != plan.items.last?.id {
                            Rectangle().fill(Color.white.opacity(0.055)).frame(height: 1).padding(.leading, 50)
                        }
                    }
                }
            }
        }
    }
}

private struct PlanItemRow: View {
    let item: HomePlanItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(item.isPrimary ? 0.18 : 0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Text(item.timeText)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .multilineTextAlignment(.trailing)
                }

                Text(item.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var color: Color {
        switch item.tone {
        case .good:
            return Color(red: 0.3, green: 0.85, blue: 0.58)
        case .caution:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .danger:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .info:
            return Color(red: 0.4, green: 0.72, blue: 1.0)
        }
    }
}

private struct HomeAssistantCard: View {
    let assistant: HomeAssistantViewState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(accentColor.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: assistant.symbolName)
                        .font(.system(size: 19, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(accentColor)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.text("assistant_today_summary"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(assistant.headline)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(assistant.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.54))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 14)

            if assistant.signals.isEmpty == false {
                Divider().background(Color.white.opacity(0.07)).padding(.horizontal, 18)

                VStack(spacing: 14) {
                    ForEach(assistant.signals) { signal in
                        AssistantTipRow(signal: signal)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var accentColor: Color {
        switch assistant.tone {
        case .good:
            return Color(red: 0.3, green: 0.85, blue: 0.58)
        case .caution:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .danger:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .info:
            return Color(red: 0.4, green: 0.72, blue: 1.0)
        }
    }
}

private struct AssistantTipRow: View {
    let signal: HomeAssistantSignal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: signal.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(signal.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(signal.subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(signal.hint)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }

    private var iconColor: Color {
        switch signal.tone {
        case .good:
            return Color(red: 0.3, green: 0.85, blue: 0.58)
        case .caution:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .danger:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .info:
            return Color(red: 0.4, green: 0.72, blue: 1.0)
        }
    }
}

private struct HomeEnvironmentCard: View {
    let environment: HomeEnvironmentViewState

    var body: some View {
        GlassCard(accentColor: Color(red: 0.35, green: 0.82, blue: 0.66)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    CardSectionHeader(
                        title: environment.title,
                        icon: "heart.text.square.fill",
                        color: Color(red: 0.35, green: 0.82, blue: 0.66)
                    )
                    Spacer(minLength: 8)
                    Text(environment.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 138), spacing: 10)], spacing: 10) {
                    ForEach(environment.signals) { signal in
                        EnvironmentSignalTile(signal: signal)
                    }
                }
            }
        }
    }
}

private struct EnvironmentSignalTile: View {
    let signal: HomeEnvironmentSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(signal.isAvailable ? 0.15 : 0.08))
                        .frame(width: 30, height: 30)
                    Image(systemName: signal.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color.opacity(signal.isAvailable ? 1 : 0.55))
                }
                Text(signal.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(signal.isAvailable ? 0.62 : 0.38))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(signal.value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(signal.isAvailable ? Color.white : Color.white.opacity(0.42))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)

            Text(signal.detail)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(signal.isAvailable ? 0.44 : 0.30))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
        .padding(12)
        .background(Color.white.opacity(signal.isAvailable ? 0.045 : 0.026), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(signal.isAvailable ? 0.16 : 0.08), lineWidth: 1)
        )
    }

    private var color: Color {
        switch signal.tone {
        case .good:
            return Color(red: 0.3, green: 0.85, blue: 0.58)
        case .caution:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .danger:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        case .info:
            return Color(red: 0.4, green: 0.72, blue: 1.0)
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
            .padding(16)
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
                .lineLimit(2)
                .minimumScaleFactor(0.75)
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
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        weatherSummary
                        Spacer(minLength: 12)
                        weatherIcon
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            weatherSummary
                            Spacer(minLength: 8)
                        }
                        weatherIcon
                    }
                }

                // Metrics row
                VStack(spacing: 8) {
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

                    if let sunriseText = weather.sunriseText, let sunsetText = weather.sunsetText {
                        HStack(spacing: 0) {
                            MetricPill(icon: "sunrise.fill", value: sunriseText, color: Color(red: 1.0, green: 0.7, blue: 0.3))
                            Spacer()
                            Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 28)
                            Spacer()
                            MetricPill(icon: "sunset.fill", value: sunsetText, color: Color(red: 0.9, green: 0.5, blue: 0.3))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.top, 16)

                // Divider
                Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1).padding(.top, 16)

                // Decision row
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 14) {
                        decisionCopy
                        Spacer(minLength: 10)
                        scoreRing
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        decisionCopy
                        scoreRing
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.top, 16)
            }
        }
    }

    private var decisionColor: Color { AppTheme.color(for: recommendation.outdoorDecision) }

    private var weatherSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(weather.temperatureText)
                .font(.system(size: 68, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    conditionText
                    highLowText
                }

                VStack(alignment: .leading, spacing: 3) {
                    conditionText
                    highLowText
                }
            }

            Text(weather.feelsLikeText)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.35))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
        .layoutPriority(1)
    }

    private var conditionText: some View {
        Text(weather.conditionText)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.8))
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var highLowText: some View {
        HStack(spacing: 4) {
            Text("H:\(weather.highTempText)")
            Text("L:\(weather.lowTempText)")
        }
        .font(.system(size: 13))
        .foregroundStyle(Color.white.opacity(0.4))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private var weatherIcon: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Image(systemName: weather.symbolName)
                .font(.system(size: 56))
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(Color.white.opacity(0.3))
            }
        }
    }

    private var decisionCopy: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(decisionColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: decisionColor.opacity(0.7), radius: 4)
                Text(recommendation.outdoorDecision.localizedTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(recommendation.summaryText)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.45))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            if let best = recommendation.bestOutdoorWindow {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill").font(.system(size: 10))
                    Text(best.shortDisplayText).font(.system(size: 12))
                }
                .foregroundStyle(sky)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
        }
        .layoutPriority(1)
    }

    private var scoreRing: some View {
        ScoreRingView(score: recommendation.outdoorScore, size: 72, showOutOf100: true)
            .environment(\.colorScheme, .dark)
    }
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
                .lineLimit(1)
                .minimumScaleFactor(0.70)
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
                .layoutPriority(1)
        }
        .padding(14)
        .background(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.22), lineWidth: 1))
    }
}

// MARK: - Hourly card (Apple Weather style)

private struct HomeHourlyCard: View {
    let hourlyScores: [HourlyScoreItem]
    let recommendation: DailyRecommendation

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("home_hourly_label"), icon: "clock.fill")

                if hourlyScores.isEmpty {
                    Text(L10n.text("weather_limited_data"))
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.48))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(hourlyScores.prefix(24)) { item in
                                HourlyScoreCell(item: item, isBestWindow: isInBestWindow(date: item.date))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if let bestWindow = recommendation.bestOutdoorWindow {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.58))
                        Text(L10n.text("home_hourly_best_window")).font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.45))
                        Text(bestWindow.shortDisplayText).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.3, green: 0.85, blue: 0.58))
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    private func isInBestWindow(date: Date) -> Bool {
        guard let window = recommendation.bestOutdoorWindow else { return false }
        return date >= window.start && date < window.end
    }
}

private struct HourlyScoreCell: View {
    let item: HourlyScoreItem
    var isBestWindow: Bool = false

    private var color: Color {
        switch item.score {
        case 80...100: return Color(red: 0.3, green: 0.85, blue: 0.6)
        case 60..<80:  return Color(red: 0.4, green: 0.72, blue: 1.0)
        case 40..<60:  return Color(red: 1.0, green: 0.7, blue: 0.3)
        default:       return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }

    var body: some View {
        VStack(spacing: 7) {
            Text(String(format: "%02d", item.hour))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.45))

            Image(systemName: item.symbolName)
                .font(.system(size: 18))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)

            Text(item.temperatureText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 5, height: 34)
                Capsule()
                    .fill(color.opacity(0.75))
                    .frame(width: 5, height: max(4, CGFloat(item.score) * 0.34))
            }

            VStack(spacing: 2) {
                Text("\(item.score)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()

                if item.precipitationChance >= 0.2 {
                    HStack(spacing: 2) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 7))
                        Text("\(Int((item.precipitationChance * 100).rounded()))%")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(Color(red: 0.45, green: 0.68, blue: 1.0).opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isBestWindow ? Color(red: 0.3, green: 0.85, blue: 0.6).opacity(0.12) : color.opacity(item.score >= 60 ? 0.07 : 0))
        }
        .overlay {
            if isBestWindow {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.3, green: 0.85, blue: 0.6).opacity(0.4), lineWidth: 1)
            }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(forecast.dayName)
                    .font(.system(size: 15, weight: forecast.isToday ? .semibold : .regular))
                    .foregroundStyle(forecast.isToday ? .white : Color.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(minWidth: 36, alignment: .leading)

                Image(systemName: forecast.conditionSymbol)
                    .font(.system(size: 17))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(sky)
                    .frame(width: 24)

                precipitationView

                Spacer(minLength: 8)

                temperatureText
            }

            TempRangeBar(low: forecast.lowTemp, high: forecast.highTemp, range: range)
                .frame(height: 5)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var precipitationView: some View {
        if forecast.precipitationChance >= 0.2 {
            HStack(spacing: 2) {
                Image(systemName: "drop.fill").font(.system(size: 9))
                Text(String(format: "%.0f%%", forecast.precipitationChance * 100)).font(.system(size: 11))
            }
            .foregroundStyle(rain.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
    }

    private var temperatureText: some View {
        HStack(spacing: 6) {
            Text(forecast.lowTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .foregroundStyle(Color.white.opacity(0.3))
            Text(forecast.highTemp.formatted(.number.precision(.fractionLength(0))) + "°")
                .foregroundStyle(.white)
        }
        .font(.system(size: 15, weight: .medium))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
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
                    .lineLimit(2)
                Text(rec.bestWindow.shortDisplayText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

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
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Quick Tips card

private struct HomeQuickTipsCard: View {
    let recommendation: DailyRecommendation
    let currentWeather: HomeCurrentWeatherViewState

    var body: some View {
        GlassCard(accentColor: Color(red: 0.4, green: 0.72, blue: 1.0)) {
            VStack(alignment: .leading, spacing: 14) {
                CardSectionHeader(title: L10n.text("quick_tips_title"), icon: "lightbulb.fill", color: Color(red: 1.0, green: 0.85, blue: 0.35))

                VStack(spacing: 12) {
                    if let windKph = extractWindSpeed(from: currentWeather.windText), windKph > 25 {
                        QuickTipRow(
                            icon: "wind",
                            iconColor: Color(red: 0.4, green: 0.7, blue: 1.0),
                            text: L10n.text("quick_tip_windy")
                        )
                    }

                    if let humidity = Double(currentWeather.humidityText.replacingOccurrences(of: "%", with: "")), humidity > 80 {
                        QuickTipRow(
                            icon: "humidity.fill",
                            iconColor: Color(red: 0.35, green: 0.65, blue: 0.9),
                            text: L10n.text("quick_tip_humid")
                        )
                    }

                    if let uv = Int(currentWeather.uvIndexText), uv >= 6 {
                        QuickTipRow(
                            icon: "sun.max.fill",
                            iconColor: Color(red: 1.0, green: 0.65, blue: 0.2),
                            text: String(format: L10n.text("quick_tip_uv"), uv)
                        )
                    }

                    if !recommendation.avoidWindows.isEmpty, let avoidWindow = recommendation.avoidWindows.first {
                        QuickTipRow(
                            icon: "xmark.circle.fill",
                            iconColor: Color(red: 1.0, green: 0.4, blue: 0.4),
                            text: String(format: L10n.text("quick_tip_avoid"), avoidWindow.window.start.formatted(date: .omitted, time: .shortened))
                        )
                    }

                    if recommendation.outdoorDecision == .good {
                        QuickTipRow(
                            icon: "checkmark.circle.fill",
                            iconColor: Color(red: 0.35, green: 0.85, blue: 0.6),
                            text: L10n.text("quick_tip_good_day")
                        )
                    }
                }
            }
        }
    }

    private func extractWindSpeed(from text: String) -> Double? {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(numbers)
    }
}

private struct QuickTipRow: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    .lineLimit(2)
                Text(risk.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
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
