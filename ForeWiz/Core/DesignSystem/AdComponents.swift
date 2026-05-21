import SwiftUI

// MARK: - Glass Ad Banner
/// Elegant banner ad component that matches ForeWiz's Liquid Glass design system.
struct GlassAdBanner: View {
    let adUnit: AdManager.AdUnitID
    @State private var isVisible = false
    @State private var isLoading = true
    
    private let accent = Color.blue
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                adPlaceholder
            } else {
                adContent
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .animation(AppTheme.cardSpring, value: isVisible)
        .onAppear {
            withAnimation(AppTheme.cardSpring.delay(0.3)) {
                isVisible = true
            }
            loadAd()
        }
    }
    
    @ViewBuilder
    private var adPlaceholder: some View {
        GlassCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 12)
                        .frame(width: 120)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                        .frame(width: 80)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 24)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
    }
    
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
                
                Text(L10n.text("ad_learn_more"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        accent.opacity(0.15)
                            .clipShape(Capsule())
                    )
            }
            .padding(.horizontal, 4)
        }
        .onTapGesture {
            AdManager.shared.trackClick(for: adUnit)
        }
    }
    
    private var adIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.3),
                            accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accent)
        }
    }
    
    private func loadAd() {
        guard AdManager.shared.canShowBanner() else { return }
        
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            AdManager.shared.recordBannerShown()
        }
    }
}

// MARK: - Native Ad Card
/// Native-style ad card that blends seamlessly with content feeds.
struct NativeAdCard: View {
    let adUnit: AdManager.AdUnitID
    @State private var isVisible = false
    
    private let accent = Color.blue
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
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
                }
                
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
                                colors: [accent, accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .clipShape(Capsule())
                        )
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
            AdManager.shared.trackImpression(for: adUnit)
        }
        .onTapGesture {
            AdManager.shared.trackClick(for: adUnit)
        }
    }
    
    private var adImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        accent.opacity(0.2),
                        accent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(accent.opacity(0.6))
            }
    }
}

// MARK: - Interstitial Ad Overlay
/// Full-screen interstitial ad shown at natural break points.
struct InterstitialAdOverlay: View {
    let onDismiss: () -> Void
    @State private var canDismiss = false
    @State private var countdown = 5
    
    private let accent = Color.blue
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    interstitialContent
                    
                    if canDismiss {
                        dismissButton
                    } else {
                        countdownIndicator
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                )
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .onAppear {
            AdManager.shared.recordInterstitialShown()
            startCountdown()
        }
    }
    
    private var interstitialContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(accent)
            
            Text(L10n.text("ad_interstitial_title"))
                .font(.system(size: 22, weight: .bold))
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
        Button(action: onDismiss) {
            Text(L10n.text("ad_continue"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(Capsule())
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
    
    private var countdownIndicator: some View {
        VStack(spacing: 8) {
            Text(L10n.formatted("ad_dismiss_in", countdown))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            ProgressView(value: Double(5 - countdown), total: 5)
                .progressViewStyle(LinearProgressViewStyle(tint: accent))
                .frame(width: 100)
        }
    }
    
    private func startCountdown() {
        Task {
            for i in 1...5 {
                try? await Task.sleep(for: .seconds(1))
                countdown = i
                if Task.isCancelled { return }
            }
            canDismiss = true
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            GlassAdBanner(adUnit: .homeBanner)
            NativeAdCard(adUnit: .nativeCard)
        }
        .padding()
    }
    .background(Color.black)
}
