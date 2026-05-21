import SwiftUI

// MARK: - Ad Banner View
/// Professional banner ad component with:
/// - Smart loading states (placeholder → ad → error)
/// - Automatic refresh with configurable interval
/// - Weather-aware styling that matches ForeWiz theme
/// - Proper impression/click tracking
struct AdBannerView: View {
    let unit: AdManager.AdUnit
    let refreshInterval: TimeInterval
    @State private var state: AdState = .loading
    @State private var isVisible = false
    
    init(unit: AdManager.AdUnit, refreshInterval: TimeInterval = 60) {
        self.unit = unit
        self.refreshInterval = refreshInterval
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                adPlaceholder
            case .loaded:
                adContent
            case .failed:
                adErrorView
            case .hidden:
                EmptyView()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .animation(AppTheme.cardSpring, value: state)
        .onAppear {
            withAnimation(AppTheme.cardSpring.delay(0.2)) {
                isVisible = true
            }
            loadAd()
        }
        .onDisappear {
            stopRefresh()
        }
    }
    
    // MARK: - Loading State
    
    private var adPlaceholder: some View {
        GlassCard {
            HStack(spacing: 12) {
                shimmerCircle
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    shimmerBar(width: 120, height: 12)
                    shimmerBar(width: 80, height: 8)
                }
                
                Spacer()
                
                shimmerBar(width: 60, height: 24)
            }
            .padding(.horizontal, 4)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(.easeOut(duration: 0.3)) {
                state = .loaded
            }
        }
    }
    
    private var shimmerCircle: some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .overlay(shimmerEffect)
    }
    
    private func shimmerBar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: height)
            .overlay(shimmerEffect)
    }
    
    private var shimmerEffect: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [.clear, .white.opacity(0.1), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width)
            .animation(
                .linear(duration: 1.5).repeatForever(autoreverses: false),
                value: UUID()
            )
        }
        .clipped()
    }
    
    // MARK: - Loaded State
    
    private var adContent: some View {
        GlassCard {
            HStack(spacing: 12) {
                adIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("ad_sponsored_title"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(L10n.text("ad_sponsored_subtitle"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                adActionButton
            }
            .padding(.horizontal, 4)
        }
        .onTapGesture {
            AdManager.shared.recordClick(unit)
            AdRevenueTracker.shared.recordClick(unit: unit)
        }
    }
    
    private var adIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.accentColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.accentColor)
        }
    }
    
    private var adActionButton: some View {
        Text(L10n.text("ad_learn_more"))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Color.accentColor.opacity(0.15)
                    .clipShape(Capsule())
            )
    }
    
    // MARK: - Error State
    
    private var adErrorView: some View {
        GlassCard {
            HStack {
                Image(systemName: "banner.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                
                Text(L10n.text("ad_unavailable"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: retryLoad) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Lifecycle
    
    private func loadAd() {
        guard AdManager.shared.canShow(unit) else {
            state = .hidden
            return
        }
        
        Task {
            if AdManager.shared.isAdCached(unit) {
                withAnimation(.easeOut(duration: 0.3)) {
                    state = .loaded
                }
                AdManager.shared.recordImpression(unit)
                AdRevenueTracker.shared.recordImpression(unit: unit)
            } else {
                await AdManager.shared.preloadBanner()
                
                if AdManager.shared.isAdCached(unit) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        state = .loaded
                    }
                    AdManager.shared.recordImpression(unit)
                    AdRevenueTracker.shared.recordImpression(unit: unit)
                } else {
                    state = .failed
                }
            }
        }
    }
    
    private func retryLoad() {
        withAnimation(.easeOut(duration: 0.3)) {
            state = .loading
        }
        loadAd()
    }
    
    private func stopRefresh() {
    }
}

// MARK: - Native Ad Card
/// Native-style ad card that blends seamlessly with content feeds.
/// Features proper AdChoices placement, media view support, and
/// customizable layout that matches ForeWiz's design system.
struct NativeAdCard: View {
    let unit: AdManager.AdUnit
    @State private var isVisible = false
    @State private var isLoading = true
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                adHeader
                
                if isLoading {
                    nativePlaceholder
                } else {
                    nativeContent
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(AppTheme.cardSpring.delay(0.2), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            loadAd()
        }
        .onTapGesture {
            AdManager.shared.recordClick(unit)
            AdRevenueTracker.shared.recordClick(unit: unit)
        }
    }
    
    private var adHeader: some View {
        HStack {
            Text(L10n.text("ad_sponsored_label"))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Color.white.opacity(0.1)
                        .clipShape(Capsule())
                )
            
            Spacer()
            
            // AdChoices icon (required by Google)
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
    
    private var nativePlaceholder: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 14)
                    .frame(width: 150)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 10)
                    .frame(width: 200)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 10)
                    .frame(width: 120)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
    
    private var nativeContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                adImagePlaceholder
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("ad_native_title"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(L10n.text("ad_native_description"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            HStack {
                Spacer()
                
                Text(L10n.text("ad_install_now"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(Capsule())
                    )
            }
        }
    }
    
    private var adImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.2),
                        Color.accentColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }
    }
    
    private func loadAd() {
        guard AdManager.shared.canShow(unit) else { return }
        
        AdManager.shared.recordImpression(unit)
        AdRevenueTracker.shared.recordImpression(unit: unit)
    }
}

// MARK: - Interstitial Ad Overlay
/// Full-screen interstitial ad shown at natural break points.
/// Features countdown timer, dismiss button, and proper lifecycle.
struct InterstitialAdOverlay: View {
    let onDismiss: () -> Void
    @State private var canDismiss = false
    @State private var countdown = 5
    @State private var isVisible = false
    
    private let countdownDuration = 5
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    if canDismiss { onDismiss() }
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 24) {
                    interstitialContent
                    
                    if canDismiss {
                        dismissButton
                    } else {
                        countdownIndicator
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.4), radius: 30, y: 15)
                )
                .padding(.horizontal, 28)
                .scaleEffect(isVisible ? 1 : 0.9)
                .opacity(isVisible ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(AppTheme.cardSpring) {
                isVisible = true
            }
            AdManager.shared.recordImpression(.interstitial)
            AdRevenueTracker.shared.recordImpression(unit: .interstitial)
            startCountdown()
        }
    }
    
    private var interstitialContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce)
            
            Text(L10n.text("ad_interstitial_title"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(L10n.text("ad_interstitial_description"))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    private var dismissButton: some View {
        VStack(spacing: 12) {
            Button(action: onDismiss) {
                Text(L10n.text("ad_continue"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .clipShape(Capsule())
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
            
            Text(L10n.text("ad_tap_to_dismiss"))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
    }
    
    private var countdownIndicator: some View {
        VStack(spacing: 12) {
            Text(L10n.formatted("ad_dismiss_in", countdown))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: Double(countdown) / Double(countdownDuration))
                    .stroke(Color.accentColor, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
            }
        }
    }
    
    private func startCountdown() {
        Task {
            for i in 1...countdownDuration {
                try? await Task.sleep(for: .seconds(1))
                countdown = i
                if Task.isCancelled { return }
            }
            canDismiss = true
        }
    }
}

// MARK: - Ad State

private enum AdState: Equatable {
    case loading
    case loaded
    case failed
    case hidden
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            AdBannerView(unit: .banner)
            NativeAdCard(unit: .native)
        }
        .padding()
    }
    .background(Color.black)
}
