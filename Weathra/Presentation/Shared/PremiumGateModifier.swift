import SwiftUI

struct PremiumGateModifier: ViewModifier {
    let feature: PremiumFeature
    let tier: SubscriptionTier
    let onTap: () -> Void
    
    func body(content: Content) -> some View {
        if FeatureGate.isUnlocked(feature, tier: tier) {
            content
        } else {
            Button(action: onTap) {
                HStack {
                    content
                        .disabled(true)
                        .opacity(0.6)
                    
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warning)
                }
                .overlay(
                    HStack {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.warning)
                    }
                    .padding(.trailing, 4)
                )
            }
        }
    }
}

extension View {
    func premiumGate(feature: PremiumFeature, tier: SubscriptionTier, onTap: @escaping () -> Void) -> some View {
        modifier(PremiumGateModifier(feature: feature, tier: tier, onTap: onTap))
    }
}
