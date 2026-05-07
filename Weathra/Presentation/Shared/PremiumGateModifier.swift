import SwiftUI

struct PremiumGateModifier: ViewModifier {
    let feature: PremiumFeature
    let tier: SubscriptionTier
    let onTap: () -> Void

    func body(content: Content) -> some View {
        Group {
            if FeatureGate.isUnlocked(feature, tier: tier) {
                content
            } else {
                content
                    .disabled(true)
                    .opacity(0.5)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.warning)
                            .padding(6)
                    }
                    .onTapGesture(perform: onTap)
            }
        }
    }
}

extension View {
    func premiumGate(feature: PremiumFeature, tier: SubscriptionTier, onTap: @escaping () -> Void) -> some View {
        modifier(PremiumGateModifier(feature: feature, tier: tier, onTap: onTap))
    }
}
