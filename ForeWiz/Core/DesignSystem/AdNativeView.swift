import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - Native Ad View
/// Professional native ad view that conforms to Google's requirements.
struct AdNativeView: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> ForeWizNativeAdView {
        let container = ForeWizNativeAdView()
        container.configure(with: nativeAd)
        return container
    }
    
    func updateUIView(_ uiView: ForeWizNativeAdView, context: Context) {
        uiView.configure(with: nativeAd)
    }
}

// MARK: - Native Ad View Container
/// Custom native ad view using composition with GAD's NativeAdView.

final class ForeWizNativeAdView: UIView {
    private let gadNativeAdView = NativeAdView()
    private let mediaView = MediaView()
    private let iconView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let priceLabel = UILabel()
    private let storeLabel = UILabel()
    private let starRatingImageView = UIImageView()
    private let callToActionButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.masksToBounds = true
        
        // Add GAD's NativeAdView as subview
        addSubview(gadNativeAdView)
        gadNativeAdView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gadNativeAdView.topAnchor.constraint(equalTo: topAnchor),
            gadNativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gadNativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gadNativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Background
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(white: 0.15, alpha: 0.8)
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor(white: 0.3, alpha: 0.3).cgColor
        gadNativeAdView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: gadNativeAdView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: gadNativeAdView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: gadNativeAdView.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: gadNativeAdView.bottomAnchor)
        ])
        
        // Icon
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        gadNativeAdView.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: gadNativeAdView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: gadNativeAdView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        // Headline
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        gadNativeAdView.addSubview(headlineLabel)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineLabel.topAnchor.constraint(equalTo: gadNativeAdView.topAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: gadNativeAdView.trailingAnchor, constant: -16)
        ])
        
        // Advertiser
        advertiserLabel.font = .systemFont(ofSize: 12, weight: .medium)
        advertiserLabel.textColor = .secondaryLabel
        gadNativeAdView.addSubview(advertiserLabel)
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            advertiserLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4)
        ])
        
        // Body
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        gadNativeAdView.addSubview(bodyLabel)
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bodyLabel.leadingAnchor.constraint(equalTo: gadNativeAdView.leadingAnchor, constant: 16),
            bodyLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: gadNativeAdView.trailingAnchor, constant: -16)
        ])
        
        // Media View
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 12
        gadNativeAdView.addSubview(mediaView)
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mediaView.leadingAnchor.constraint(equalTo: gadNativeAdView.leadingAnchor, constant: 16),
            mediaView.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: gadNativeAdView.trailingAnchor, constant: -16),
            mediaView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Price
        priceLabel.font = .systemFont(ofSize: 13, weight: .medium)
        priceLabel.textColor = .secondaryLabel
        gadNativeAdView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            priceLabel.leadingAnchor.constraint(equalTo: gadNativeAdView.leadingAnchor, constant: 16),
            priceLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12)
        ])
        
        // Store
        storeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        storeLabel.textColor = .secondaryLabel
        gadNativeAdView.addSubview(storeLabel)
        storeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            storeLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 12),
            storeLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12)
        ])
        
        // Star Rating
        starRatingImageView.contentMode = .scaleAspectFit
        gadNativeAdView.addSubview(starRatingImageView)
        starRatingImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            starRatingImageView.leadingAnchor.constraint(equalTo: storeLabel.trailingAnchor, constant: 12),
            starRatingImageView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 14),
            starRatingImageView.widthAnchor.constraint(equalToConstant: 80),
            starRatingImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // CTA Button — configuration set in configure() when actual ad data is available
        callToActionButton.layer.cornerRadius = 10
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = UIColor.systemBlue
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        // contentEdgeInsets explicitly not set — UIButtonConfiguration handles layout automatically on iOS 15+
        gadNativeAdView.addSubview(callToActionButton)
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            callToActionButton.trailingAnchor.constraint(equalTo: gadNativeAdView.trailingAnchor, constant: -16),
            callToActionButton.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            callToActionButton.bottomAnchor.constraint(equalTo: gadNativeAdView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with nativeAd: NativeAd) {
        // Register asset views with GAD's NativeAdView
        gadNativeAdView.headlineView = headlineLabel
        gadNativeAdView.bodyView = bodyLabel
        gadNativeAdView.iconView = iconView
        gadNativeAdView.callToActionView = callToActionButton
        gadNativeAdView.mediaView = mediaView
        gadNativeAdView.advertiserView = advertiserLabel
        gadNativeAdView.priceView = priceLabel
        gadNativeAdView.storeView = storeLabel
        gadNativeAdView.starRatingView = starRatingImageView
        
        // Populate assets
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        advertiserLabel.text = nativeAd.advertiser
        priceLabel.text = nativeAd.price
        storeLabel.text = nativeAd.store
        
        // Icon
        if let icon = nativeAd.icon {
            iconView.image = icon.image
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
        
        // Media
        mediaView.mediaContent = nativeAd.mediaContent
        
        // Star Rating
        if let starRating = nativeAd.starRating {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            starRatingImageView.image = UIImage(
                systemName: starRating.doubleValue >= 4.5 ? "star.fill" : starRating.doubleValue >= 3.5 ? "star.leadinghalf.fill" : "star",
                withConfiguration: config
            )
            starRatingImageView.isHidden = false
        } else {
            starRatingImageView.isHidden = true
        }
        
        // CTA — configure button AFTER registering it with GAD view to ensure proper layout
        if let cta = nativeAd.callToAction {
            callToActionButton.setTitle(cta, for: .normal)
            callToActionButton.isHidden = false
        } else {
            callToActionButton.setTitle(nil, for: .normal)
            callToActionButton.isHidden = true
        }
        
        // Link native ad to view
        gadNativeAdView.nativeAd = nativeAd
    }
}

// MARK: - Rewarded Ad Button
/// A button that shows a rewarded ad when tapped.
struct RewardedAdButton: View {
    let rewardText: String
    let reward: AdMobRewardedIntegration.RewardConfig
    let onRewardGranted: (AdMobRewardedIntegration.RewardConfig) -> Void
    @State private var isLoading = false
    @State private var isShowing = false
    
    var body: some View {
        Button(action: showRewardedAd) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue, .blue.opacity(0.2))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rewardText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(L10n.formatted("Watch ad to earn %lld %@", reward.amount, reward.type))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .disabled(isLoading || isShowing)
        .opacity(isLoading ? 0.7 : 1)
    }
    
    private func showRewardedAd() {
        isLoading = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isLoading = false
            return
        }
        
        let adUnitID = AdManager.AdUnit.rewarded.currentID
        
        AdMobRewardedIntegration.shared.loadRewardedAd(adUnitID: adUnitID) { success in
            isLoading = false
            
            if success {
                isShowing = true
            _ = AdMobRewardedIntegration.shared.showRewardedAd(
                    from: rootViewController,
                    reward: reward,
                    onRewardGranted: { reward in
                        isShowing = false
                        onRewardGranted(reward)
                    },
                    onRewardFailed: {
                        isShowing = false
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            RewardedAdButton(
                rewardText: "Earn Bonus Coins",
                reward: .default,
                onRewardGranted: { _ in }
            )
            .padding()
        }
    }
    .background(Color.black)
}
