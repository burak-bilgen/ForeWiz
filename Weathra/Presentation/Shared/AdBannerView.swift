import GoogleMobileAds
import SwiftUI
import UIKit

struct AdBannerView: View {
    let isPremium: Bool
    let onRemoveAdsTapped: () -> Void

    var body: some View {
        if isPremium {
            PremiumBannerView()
        } else {
            AdSpaceView(onRemoveAdsTapped: onRemoveAdsTapped)
        }
    }
}

// MARK: - Free user banner

private struct AdSpaceView: View {
    let onRemoveAdsTapped: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let adUnitID = AdMobConfiguration.bannerAdUnitID {
                GoogleAdBanner(adUnitID: adUnitID)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            Button(action: {
                HapticManager.light()
                onRemoveAdsTapped()
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.25))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.text("ad_label_text"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .lineLimit(2)
                        Text(L10n.text("premium_upgrade"))
                            .font(.system(size: 11))
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.25))
                            .lineLimit(2)
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.2))
                }
                .padding(14)
                .background(
                    Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 1.0, green: 0.78, blue: 0.25).opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct GoogleAdBanner: View {
    let adUnitID: String

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let adSize = inlineAdaptiveBanner(width: width, maxHeight: 90)
            let height = max(cgSize(for: adSize).height, 50)

            GoogleAdBannerRepresentable(adUnitID: adUnitID, adSize: adSize)
                .frame(width: width, height: height)
        }
        .frame(height: 72)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

private struct GoogleAdBannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.weathraTopViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        bannerView.rootViewController = UIApplication.shared.weathraTopViewController
        guard isAdSizeEqualToSize(size1: bannerView.adSize, size2: adSize) == false else {
            return
        }

        bannerView.adSize = adSize
        bannerView.load(Request())
    }
}

private extension UIApplication {
    var weathraTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .weathraTopPresentedViewController
    }
}

private extension UIViewController {
    var weathraTopPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.weathraTopPresentedViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.weathraTopPresentedViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.weathraTopPresentedViewController
        }

        return self
    }
}

// MARK: - Premium user banner

private struct PremiumBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
            }
            Text(L10n.text("settings_premium_active"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.6))
            Spacer()
        }
        .padding(14)
        .background(
            Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.07),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(red: 0.35, green: 0.85, blue: 0.6).opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview("Free User") {
    ZStack {
        Color(red: 0.04, green: 0.08, blue: 0.18).ignoresSafeArea()
        AdBannerView(isPremium: false, onRemoveAdsTapped: {})
            .padding()
    }
}

#Preview("Premium User") {
    ZStack {
        Color(red: 0.04, green: 0.08, blue: 0.18).ignoresSafeArea()
        AdBannerView(isPremium: true, onRemoveAdsTapped: {})
            .padding()
    }
}
