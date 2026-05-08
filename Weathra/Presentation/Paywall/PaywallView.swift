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
                        PaywallHeroSection()
                            .padding(.top, 16)

                        PaywallFeatureList()

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
        AnimatedOrbBackground(
            primary:   Color(red: 1.0, green: 0.70, blue: 0.15),
            secondary: Color(red: 0.85, green: 0.40, blue: 0.10),
            tertiary:  Color(red: 0.60, green: 0.40, blue: 1.00),
            baseColor1: Color(red: 0.06, green: 0.05, blue: 0.14),
            baseColor2: Color(red: 0.08, green: 0.06, blue: 0.18)
        )
    }
}

// MARK: - Hero section

private struct PaywallHeroSection: View {
    @State private var appeared = false
    private let gold = Color(red: 1.0, green: 0.82, blue: 0.3)

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.18))
                    .frame(width: 110, height: 110)
                    .blur(radius: 16)
                Circle()
                    .fill(LinearGradient(
                        colors: [gold, Color(red: 1.0, green: 0.6, blue: 0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .shadow(color: gold.opacity(0.50), radius: 22, x: 0, y: 8)
                Image(systemName: "crown.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color(red: 0.15, green: 0.08, blue: 0.00))
            }
            .floating(amplitude: 7, duration: 3.0)
            .pulseGlow(color: gold, radius: 18)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Text(L10n.text("paywall_title"))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Text(L10n.text("paywall_subtitle"))
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Feature list

private struct PaywallFeatureList: View {
    @State private var appeared = false

    private static let colors: [Color] = [
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.4, green: 0.85, blue: 0.6),
        Color(red: 0.8, green: 0.65, blue: 1.0),
        Color(red: 1.0, green: 0.7, blue: 0.3),
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(PremiumFeature.allCases.enumerated()), id: \.offset) { index, feature in
                let color = Self.colors[index % Self.colors.count]
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: feature.systemImage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(color)
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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(color.opacity(0.9))
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(color.opacity(0.14), lineWidth: 1))
                .staggerEntrance(index: index, appeared: appeared, baseDelay: 0.07)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }
}

// MARK: - Purchase button

private struct PaywallPurchaseButton: View {
    let product: SubscriptionProduct
    let action: () -> Void

    private let dark = Color(red: 0.06, green: 0.06, blue: 0.14)
    private let gold = Color(red: 1.0, green: 0.85, blue: 0.32)
    private let amber = Color(red: 1.0, green: 0.65, blue: 0.20)

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(dark)
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundStyle(dark.opacity(0.65))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.price)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(dark)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [gold, amber], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: amber.opacity(0.45), radius: 16, x: 0, y: 8)
            .shimmer()
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
    }
}
