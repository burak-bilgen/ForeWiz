import SwiftUI
import StoreKit

// MARK: - Premium Paywall View
struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var premiumManager = PremiumManager.shared
    @State private var selectedProductID: String?
    @State private var animateIn = false
    @State private var showThankYou = false
    
    var body: some View {
        ZStack {
            LiquidOrbBackground(palette: .clearSky)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            HapticEngine.shared.light()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    
                    // Hero
                    heroSection
                        .padding(.top, 8)
                    
                    // Feature grid
                    featureGrid
                    
                    // Pricing cards
                    if premiumManager.isLoadingProducts {
                        loadingView
                    } else if premiumManager.products.isEmpty {
                        emptyProductsView
                    } else {
                        pricingSection
                    }
                    
                    // Restore
                    restoreButton
                    
                    // Thank you overlay
                    if showThankYou {
                        thankYouSection
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Legal
                    legalFooter
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.top, 8)
        }
        .task {
            await premiumManager.loadProducts()
            withAnimation(.easeOut(duration: 0.8)) { animateIn = true }
        }
        .onChange(of: premiumManager.purchaseSuccess) { _, success in
            if success {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showThankYou = true
                }
                HapticEngine.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Hero
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.liquidAccent.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppTheme.liquidAccent)
                    .symbolEffect(.pulse, value: animateIn)
            }
            .padding(.bottom, 4)
            
            Text(L10n.text("premium_upgrade"))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text(L10n.text("premium_subtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)
    }
    
    // MARK: - Features
    
    private var featureGrid: some View {
        VStack(spacing: 10) {
            PremiumFeatureRow(
                icon: "cloud.sun.fill",
                title: L10n.text("premium_feature_forecast_14day"),
                description: L10n.text("premium_feature_forecast_14day_desc"),
                color: AppTheme.sky
            )
            PremiumFeatureRow(
                icon: "exclamationmark.triangle.fill",
                title: L10n.text("premium_feature_analytics"),
                description: L10n.text("premium_feature_analytics_desc"),
                color: AppTheme.coral
            )
            PremiumFeatureRow(
                icon: "applewatch.watchface",
                title: L10n.text("premium_feature_watch"),
                description: L10n.text("premium_feature_watch_desc"),
                color: AppTheme.royalPurple
            )
            PremiumFeatureRow(
                icon: "xmark.circle.fill",
                title: L10n.text("premium_remove_ads"),
                description: L10n.text("premium_remove_ads_desc"),
                color: AppTheme.ember
            )
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
    }
    
    // MARK: - Pricing
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(premiumManager.products, id: \.id) { product in
                    PricingCard(
                        product: product,
                        isSelected: selectedProductID == product.id,
                        onSelect: { selectedProductID = product.id },
                        savingsHint: premiumManager.yearlySavingsHint(for: product)
                    )
                }
            }
            
            // Purchase button
            if let selectedID = selectedProductID,
               let product = premiumManager.products.first(where: { $0.id == selectedID }) {
                LiquidGlassButton(
                    premiumManager.isPurchasing
                        ? L10n.text("premium_pending")
                        : L10n.formatted("premium_subscribe_format", product.displayPrice),
                    icon: "sparkles",
                    style: .primary,
                    haptic: .medium
                ) {
                    Task { await premiumManager.purchase(product) }
                }
                .disabled(premiumManager.isPurchasing)
                .opacity(premiumManager.isPurchasing ? 0.6 : 1)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Error
            if let error = premiumManager.purchaseError {
                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.coral)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 12)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: animateIn)
        .onAppear {
            // Auto-select yearly (first product is cheaper monthly, but yearly is better value)
            if selectedProductID == nil,
               let yearly = premiumManager.products.first(where: { $0.id == PremiumManager.ProductID.yearly.rawValue }) {
                selectedProductID = yearly.id
            } else if selectedProductID == nil,
                      let first = premiumManager.products.first {
                selectedProductID = first.id
            }
        }
    }
    
    // MARK: - Restore
    
    private var restoreButton: some View {
        VStack(spacing: 8) {
            Button {
                HapticEngine.shared.light()
                Task { await premiumManager.restorePurchases() }
            } label: {
                if premiumManager.isRestoring {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                } else {
                    Text(L10n.text("premium_restore"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .buttonStyle(.plain)
            .disabled(premiumManager.isRestoring)
            
            if let message = premiumManager.restoreMessage {
                Text(message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Thank You
    
    private var thankYouSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.success)
            Text(L10n.text("premium_welcome"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white.opacity(0.5))
            Text(L10n.text("premium_pending"))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 20)
    }
    
    private var emptyProductsView: some View {
        VStack(spacing: 8) {
            Text(L10n.text("premium_product_not_found"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            
            LiquidGlassButton(L10n.text("settings_retry"), icon: "arrow.clockwise", style: .tertiary) {
                Task { await premiumManager.loadProducts() }
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Legal
    
    private var legalFooter: some View {
        Text(L10n.text("premium_legal"))
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.2))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 8)
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    let savingsHint: String?
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Text(product.displayPrice)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                
                Text(product.displayPeriodTitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                
                if let savings = savingsHint {
                    Text(savings)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.success.opacity(0.15), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected
                            ? AppTheme.liquidAccent.opacity(0.5)
                            : .white.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.liquidAccent)
                        .offset(x: -6, y: 6)
                }
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Feature Row

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    PremiumPaywallView()
}
