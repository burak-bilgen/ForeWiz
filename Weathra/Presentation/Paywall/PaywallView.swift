import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: StoreKitSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppSpacing.large) {
                        Spacer().frame(height: AppSpacing.medium)

                        VStack(spacing: AppSpacing.small) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 56, weight: .bold))
                                .foregroundStyle(AppTheme.sunshine)
                                .shadow(color: AppTheme.sunshine.opacity(0.35), radius: 16, y: 8)

                            Text(String(localized: "paywall_title"))
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.ink)

                            Text(String(localized: "paywall_subtitle"))
                                .font(AppTypography.body)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.large)

                        VStack(spacing: AppSpacing.medium) {
                            ForEach(PremiumFeature.allCases) { feature in
                                PremiumBenefitRow(feature: feature)
                            }
                        }
                        .padding(.horizontal, AppSpacing.medium)

                        if store.isLoading && store.products.isEmpty {
                            ProgressView(String(localized: "paywall_loading"))
                                .padding()
                        } else {
                            VStack(spacing: AppSpacing.medium) {
                                ForEach(store.products) { product in
                                    PurchaseButton(product: product) {
                                        Task {
                                            let success = await store.purchase(product)
                                            if success {
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppSpacing.medium)
                        }

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppTheme.danger)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.medium)
                        }

                        Button(action: restore) {
                            Label(String(localized: "paywall_restore"), systemImage: "arrow.counterclockwise")
                                .font(AppTypography.caption.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.top, AppSpacing.small)

                        Text("Otomatik olarak yenilenir. İstediğin zaman Ayarlar’dan iptal edebilirsin.")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.large)

                        Spacer().frame(height: AppSpacing.medium)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .task {
                await store.loadProducts()
                await store.refreshStatus()
            }
            .alert(String(localized: "paywall_purchases"), isPresented: $showRestoreAlert) {
                Button(String(localized: "paywall_ok"), role: .cancel) {}
            } message: {
                Text(restoreSuccess
                     ? String(localized: "paywall_restore_success")
                     : String(localized: "paywall_restore_failed"))
            }
        }
    }

    private func restore() {
        Task {
            restoreSuccess = await store.restorePurchases()
            showRestoreAlert = true
        }
    }
}

private struct PremiumBenefitRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: feature.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(AppTheme.softBubbleGradient(tint: AppTheme.accent), in: RoundedRectangle(cornerRadius: AppTheme.iconBubbleRadius, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(feature.localizedTitle)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppTheme.ink)
                Text(feature.localizedDescription)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.medium)
        .background(AppTheme.elevatedSurface.opacity(0.86), in: RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
    }
}

private struct PurchaseButton: View {
    let product: SubscriptionProduct
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(AppTypography.headline)
                    Text(product.description)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Text(product.price)
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .padding(AppSpacing.medium)
            .foregroundStyle(.white)
            .background(AppTheme.weatherGradient(for: .light), in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(0.22), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(store: StoreKitSubscriptionManager())
}
