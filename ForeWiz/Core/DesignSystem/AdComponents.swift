import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - Ad Banner View
/// Professional banner ad with real Google AdMob integration.
/// Shows a real BannerView when loaded, graceful fallback on failure.
struct AdBannerView: View {
    let adUnitID: String
    @State private var state: AdLoadState = .loading
    @State private var isVisible = false
    @State private var bannerView: BannerView?
    
    init(adUnitID: String? = nil) {
        self.adUnitID = adUnitID ?? AdManager.AdUnit.banner.currentID
    }
    
    var body: some View {
        Group {
            switch state {
            case .loading:
                bannerPlaceholder
            case .loaded(let view):
                BannerHostingView(bannerView: view)
                    .frame(height: 50)
            case .failed:
                EmptyView()
            case .hidden:
                EmptyView()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .animation(AppTheme.cardSpring.delay(0.15), value: state)
        .onAppear {
            withAnimation(AppTheme.cardSpring.delay(0.2)) {
                isVisible = true
            }
            loadAd()
        }
    }
    
    // MARK: - Placeholder
    
    private var bannerPlaceholder: some View {
        GlassCard {
            HStack(spacing: 12) {
                ShimmerCircle(size: 32)
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBar(width: 100, height: 10)
                    ShimmerBar(width: 70, height: 8)
                }
                Spacer()
                ShimmerBar(width: 50, height: 20)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Lifecycle
    
    private func loadAd() {
        guard AdManager.shared.canShow(.banner) else {
            state = .hidden
            return
        }
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController else {
            state = .failed
            return
        }
        
        // Check for existing cached banner
        if let existingBanner = AdMobIntegration.shared.currentBannerView {
            withAnimation(.easeOut(duration: 0.3)) {
                state = .loaded(existingBanner)
            }
            return
        }
        
        // Load new banner
        AdMobIntegration.shared.loadBannerAd(adUnitID: adUnitID) {
            Task { @MainActor in
                if let banner = AdMobIntegration.shared.currentBannerView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.state = .loaded(banner)
                    }
                }
            }
        } onFailure: {
            Task { @MainActor in
                self.state = .failed
            }
        }
        
        // Timeout fallback
        Task {
            try? await Task.sleep(for: .seconds(10))
            if case .loading = state {
                state = .failed
            }
        }
    }
}

// MARK: - Banner Hosting View

private struct BannerHostingView: UIViewRepresentable {
    let bannerView: BannerView
    
    func makeUIView(context: Context) -> BannerView {
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - Native Ad Card
/// Native ad card that displays a real Google NativeAd.
/// Falls back gracefully if no ad is available.
struct NativeAdCard: View {
    let adUnitID: String
    @State private var isVisible = false
    @State private var nativeAd: NativeAd?
    @State private var isLoading = true
    
    init(adUnitID: String? = nil) {
        self.adUnitID = adUnitID ?? AdManager.AdUnit.native.currentID
    }
    
    var body: some View {
        Group {
            if isLoading {
                nativePlaceholder
            } else if let ad = nativeAd {
                // Real native ad via the existing AdNativeView
                AdNativeView(nativeAd: ad)
                    .frame(minHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                EmptyView()
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(AppTheme.cardSpring.delay(0.2), value: isVisible)
        .onAppear {
            withAnimation { isVisible = true }
            loadAd()
        }
    }
    
    // MARK: - Placeholder
    
    private var nativePlaceholder: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Sponsored label
                HStack {
                    Text(L10n.text("ad_sponsored_label"))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1).clipShape(Capsule()))
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    ShimmerBar(width: 60, height: 60, cornerRadius: 12)
                    VStack(alignment: .leading, spacing: 6) {
                        ShimmerBar(width: 150, height: 14)
                        ShimmerBar(width: 200, height: 10)
                        ShimmerBar(width: 120, height: 10)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    private func loadAd() {
        guard AdManager.shared.canShow(.native) else {
            isLoading = false
            return
        }
        
        // Load native ad directly (cache is handled internally by loadNativeAd)
        AdMobIntegration.shared.loadNativeAd(adUnitID: adUnitID) { ad in
            Task { @MainActor in
                self.nativeAd = ad
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isLoading = false
                }
            }
        }
        
        // Timeout fallback
        Task {
            try? await Task.sleep(for: .seconds(10))
            if isLoading {
                withAnimation { isLoading = false }
            }
        }
    }
}

// MARK: - Interstitial Ad Trigger
/// Presents a real Google interstitial ad at natural break points.
/// Shows a brief loading overlay while the ad prepares.
struct InterstitialAdTrigger: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    @State private var isShowingAd = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue { showInterstitial() }
            }
    }
    
    private func showInterstitial() {
        guard !isShowingAd else { return }
        isShowingAd = true
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController else {
            isPresented = false
            isShowingAd = false
            return
        }
        
        let success = AdMobIntegration.shared.showInterstitialAd(from: rootVC) {
            isPresented = false
            isShowingAd = false
            onDismiss()
        }
        
        if !success {
            // No ad available, proceed
            isPresented = false
            isShowingAd = false
            onDismiss()
        }
    }
}

extension View {
    /// Present a real Google interstitial ad at natural transition points.
    func interstitialAd(isPresented: Binding<Bool>, onDismiss: @escaping () -> Void = {}) -> some View {
        modifier(InterstitialAdTrigger(isPresented: isPresented, onDismiss: onDismiss))
    }
}

// MARK: - Shimmer Components (Fixed)
/// Fixed shimmer bar with proper animation using @State instead of UUID().
struct ShimmerBar: View {
    let width: CGFloat
    let height: CGFloat
    var cornerRadius: CGFloat = 4
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: height)
            .overlay(ShimmerEffect())
            .clipped()
    }
}

struct ShimmerCircle: View {
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: size, height: size)
            .overlay(ShimmerEffect())
            .clipped()
    }
}

private struct ShimmerEffect: View {
    @State private var offset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [.clear, .white.opacity(0.08), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: offset * geometry.size.width)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = 1
                }
            }
        }
    }
}

// MARK: - Ad Load State

private enum AdLoadState: Equatable {
    case loading
    case loaded(BannerView)
    case failed
    case hidden
    
    static func == (lhs: AdLoadState, rhs: AdLoadState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.loaded, .loaded): return true
        case (.failed, .failed): return true
        case (.hidden, .hidden): return true
        default: return false
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            AdBannerView()
                .padding(.horizontal)
            NativeAdCard()
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color.black)
}
