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
                .padding(.horizontal, 16)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 28) {
                        PaywallHeroSection()
                            .padding(.top, 16)

                        PaywallFeatureList()
                        PaywallValueStrip()

                        if store.isLoading && store.products.isEmpty {
                            VStack(spacing: 12) {
                                PulsingDotsLoader(color: Color(red: 1.0, green: 0.82, blue: 0.30))
                                Text(L10n.text("paywall_loading"))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .padding(.vertical, 24)
                        } else if store.products.isEmpty {
                            PaywallUnavailableState {
                                Task { await store.loadProducts() }
                            }
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
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .safeAreaPadding(.bottom, 12)
            }
        }
        .dynamicTypeSize(.large ... .xxxLarge)
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

private struct PaywallUnavailableState: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.30))
            Text(L10n.text("premium_product_not_found"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text(L10n.text("home_error_retry"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.06, green: 0.06, blue: 0.14))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Color(red: 1.0, green: 0.82, blue: 0.30),
                        in: Capsule()
                    )
            }
            .buttonStyle(PressScaleButtonStyle(scale: 0.96))
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
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
                .lineLimit(3)
                .minimumScaleFactor(0.80)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

            Text(L10n.text("paywall_subtitle"))
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
                            .lineLimit(2)
                        Text(feature.localizedDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 8)
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

private struct PaywallValueStrip: View {
    private let items: [(String, String, Color)] = [
        ("calendar", "14 days", Color(red: 0.4, green: 0.7, blue: 1.0)),
        ("xmark.square", "No ads", Color(red: 0.4, green: 0.85, blue: 0.6)),
        ("chart.line.uptrend.xyaxis", "Insights", Color(red: 0.8, green: 0.65, blue: 1.0)),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.1) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.0)
                        .font(.system(size: 12, weight: .semibold))
                    Text(localized(item.1))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(item.2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(item.2.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(item.2.opacity(0.16), lineWidth: 1)
                )
            }
        }
    }

    private func localized(_ value: String) -> String {
        guard L10n.currentLanguageCode == "tr" else { return value }
        switch value {
        case "14 days": return "14 gün"
        case "No ads": return "Reklamsız"
        case "Insights": return "Analiz"
        default: return value
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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    productCopy
                    Spacer(minLength: 10)
                    productPrice
                }

                VStack(alignment: .leading, spacing: 10) {
                    productCopy
                    productPrice
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [gold, amber], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .shadow(color: amber.opacity(0.45), radius: 16, x: 0, y: 8)
            .shimmerEffect()
        }
        .buttonStyle(PressScaleButtonStyle(scale: 0.97))
    }

    private var productCopy: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let badgeText {
                Text(badgeText)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(dark)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.28), in: Capsule())
            }
            Text(product.displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(dark)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(product.description)
                .font(.system(size: 12))
                .foregroundStyle(dark.opacity(0.65))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    private var productPrice: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(product.price)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(dark)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            if product.period.isEmpty == false {
                Text(periodText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(dark.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private var isYearlyPlan: Bool {
        let haystack = "\(product.id) \(product.period) \(product.displayName)".lowercased()
        return haystack.contains("year") || haystack.contains("annual") || haystack.contains("yıl")
    }

    private var badgeText: String? {
        guard isYearlyPlan else { return nil }
        return L10n.currentLanguageCode == "tr" ? "En mantıklı seçenek" : "Best value"
    }

    private var periodText: String {
        guard product.period.isEmpty == false else { return "" }
        return L10n.currentLanguageCode == "tr" ? "\(product.period) plan" : "\(product.period) plan"
    }
}
