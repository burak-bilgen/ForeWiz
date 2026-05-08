import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: StoreKitSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)

                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 64))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)

                            Text(L10n.text("paywall_title"))
                                .font(.system(size: 32, weight: .bold))

                            Text(L10n.text("paywall_subtitle"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(PremiumFeature.allCases) { feature in
                                ModernBenefitRow(feature: feature)
                            }
                        }
                        .padding(.horizontal, 20)

                        if store.isLoading && store.products.isEmpty {
                            ProgressView(L10n.text("paywall_loading"))
                                .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.products) { product in
                                    ModernPurchaseButton(product: product) {
                                        Task {
                                            let success = await store.purchase(product)
                                            if success {
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        Button(action: restore) {
                            Text(L10n.text("paywall_restore"))
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        .padding(.top, 8)

                        Text(L10n.text("premium_auto_renew"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 20)
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
                            .foregroundStyle(.secondary)
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
        HapticManager.light()
        Task {
            restoreSuccess = await store.restorePurchases()
            showRestoreAlert = true
        }
    }
}

private struct ModernBenefitRow: View {
    let feature: PremiumFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.localizedTitle)
                    .font(.headline)
                Text(feature.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            Color(UIColor.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

private struct ModernPurchaseButton: View {
    let product: SubscriptionProduct
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                Spacer()
                Text(product.price)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
