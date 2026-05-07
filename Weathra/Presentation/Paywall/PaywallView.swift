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
                                .font(.system(size: 48, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AppTheme.sunshine)

                            Text(L10n.text("paywall_title"))
                                .font(AppTypography.title)
                                .foregroundStyle(AppTheme.ink)

                            Text(L10n.text("paywall_subtitle"))
                                .font(AppTypography.callout)
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
                            ProgressView(L10n.text("paywall_loading"))
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
                            Label(L10n.text("paywall_restore"), systemImage: "arrow.counterclockwise")
                                .font(AppTypography.caption.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.top, AppSpacing.small)

                        Text(L10n.text("premium_auto_renew"))
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
                    Button {
                        dismiss()
                    } label: {
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
            .alert(L10n.text("paywall_purchases"), isPresented: $showRestoreAlert) {
                Button(L10n.text("paywall_ok"), role: .cancel) {}
            } message: {
                Text(restoreSuccess
                     ? L10n.text("paywall_restore_success")
                     : L10n.text("paywall_restore_failed"))
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
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.iconBubbleRadius, style: .continuous)
                    .fill(AppTheme.softBubble(AppTheme.accent))
                Image(systemName: feature.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 40, height: 40)

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
    }
}

private struct PurchaseButton: View {
    let product: SubscriptionProduct
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(AppTypography.bodyEmphasized)
                    Text(product.description)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Text(product.price)
                    .font(AppTypography.metricNumber)
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.86)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
            )
            .shadow(color: AppTheme.accent.opacity(0.20), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(store: StoreKitSubscriptionManager())
}
