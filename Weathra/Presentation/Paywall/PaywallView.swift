import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: StoreKitSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreAlert = false
    @State private var restoreSuccess = false

    var body: some View {
        ZStack {
            PaywallBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.82, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.15)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.4), radius: 20, x: 0, y: 8)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(Color(red: 0.15, green: 0.1, blue: 0.0))
                            }

                            Text(L10n.text("paywall_title"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Text(L10n.text("paywall_subtitle"))
                                .font(.system(size: 15))
                                .foregroundStyle(Color.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        VStack(spacing: 10) {
                            ForEach(PremiumFeature.allCases) { feature in
                                PaywallFeatureRow(feature: feature)
                            }
                        }

                        if store.isLoading && store.products.isEmpty {
                            HStack(spacing: 12) {
                                ProgressView().tint(.white)
                                Text(L10n.text("paywall_loading"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(store.products) { product in
                                    PaywallPurchaseButton(product: product) {
                                        Task {
                                            let success = await store.purchase(product)
                                            if success { dismiss() }
                                        }
                                    }
                                }
                            }
                        }

                        if let errorMessage = store.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 10) {
                            Button(action: restore) {
                                Text(L10n.text("paywall_restore"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            Text(L10n.text("premium_auto_renew"))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.25))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
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

    private func restore() {
        HapticManager.light()
        Task {
            restoreSuccess = await store.restorePurchases()
            showRestoreAlert = true
        }
    }
}

// MARK: - Background

private struct PaywallBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.14), Color(red: 0.08, green: 0.06, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.12))
                .frame(width: 320).blur(radius: 80)
                .offset(y: -180)
            Circle()
                .fill(Color.blue.opacity(0.06))
                .frame(width: 250).blur(radius: 60)
                .offset(y: 280)
        }
    }
}

// MARK: - Feature row

private struct PaywallFeatureRow: View {
    let feature: PremiumFeature

    private static let colors: [Color] = [
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.4, green: 0.85, blue: 0.6),
        Color(red: 0.8, green: 0.65, blue: 1.0),
        Color(red: 1.0, green: 0.7, blue: 0.3),
    ]

    private var accentColor: Color {
        let index = PremiumFeature.allCases.firstIndex(of: feature) ?? 0
        return Self.colors[index % Self.colors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: feature.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.localizedTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(feature.localizedDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(accentColor.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Purchase button

private struct PaywallPurchaseButton: View {
    let product: SubscriptionProduct
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.14))
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.14).opacity(0.6))
                        .lineLimit(2)
                }
                Spacer()
                Text(product.price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.14))
                    .monospacedDigit()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.85, blue: 0.32), Color(red: 1.0, green: 0.65, blue: 0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
