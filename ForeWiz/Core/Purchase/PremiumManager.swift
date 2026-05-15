import Foundation
import StoreKit
import OSLog

// MARK: - Premium Manager
/// Manages StoreKit 2 in-app purchases for the ForeWiz Premium subscription.
@MainActor
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable, Sendable {
        case monthly = "com.forewiz.premium.monthly"
        case yearly = "com.forewiz.premium.yearly"
    }

    // MARK: - Published State
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var purchaseError: String?
    private(set) var purchaseSuccess = false
    private(set) var isRestoring = false
    private(set) var restoreMessage: String?

    // MARK: - Observer Setup
    private var observerStarted = false

    private init() {}

    // MARK: - Load Products

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        purchaseError = nil

        // Start transaction observer once (singleton — lives for app lifetime)
        if !observerStarted {
            observerStarted = true
            Task { [weak self] in
                for await result in Transaction.updates {
                    guard let self = self else { break }
                    do {
                        let transaction = try self.checkVerified(result)
                        if transaction.revocationDate == nil {
                            FeatureGate.currentTier = .premium
                        } else {
                            FeatureGate.currentTier = .free
                        }
                        await transaction.finish()
                    } catch {
                        AppLogger.app.error("Transaction update error: \(error.localizedDescription)")
                    }
                }
            }
        }

        do {
            let productIDs = ProductID.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            AppLogger.app.error("Failed to load StoreKit products: \(error.localizedDescription)")
            purchaseError = L10n.text("premium_network_error")
        }

        isLoadingProducts = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        purchaseSuccess = false

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await processPurchase(transaction)
                await transaction.finish()
                purchaseSuccess = true

            case .userCancelled:
                AppLogger.app.info("User cancelled premium purchase")

            case .pending:
                AppLogger.app.info("Premium purchase pending (parental approval)")

            @unknown default:
                break
            }
        } catch {
            AppLogger.app.error("Purchase failed: \(error.localizedDescription)")
            purchaseError = L10n.text("premium_network_error")
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        restoreMessage = nil

        do {
            try await AppStore.sync()

            let hasPremium = await hasActiveSubscription()

            if hasPremium {
                FeatureGate.currentTier = .premium
                restoreMessage = L10n.text("premium_restore_success")
            } else {
                restoreMessage = L10n.text("premium_restore_none")
            }
        } catch {
            AppLogger.app.error("Restore failed: \(error.localizedDescription)")
            restoreMessage = L10n.text("premium_network_error")
        }

        isRestoring = false
    }

    // MARK: - Subscription Status

    func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                guard let _ = ProductID(rawValue: transaction.productID) else {
                    continue
                }

                if transaction.revocationDate == nil,
                   transaction.expirationDate.map({ $0 > Date() }) ?? true {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }

    // MARK: - Savings Hint

    func yearlySavingsHint(for yearlyProduct: Product) -> String? {
        let monthlyProduct = products.first {
            $0.type == .autoRenewable &&
            $0.subscription?.subscriptionPeriod.unit == .month
        }
        guard let monthly = monthlyProduct else { return nil }
        let monthlyDecimal = NSDecimalNumber(decimal: monthly.price)
        let yearlyDecimal = NSDecimalNumber(decimal: yearlyProduct.price)
        let yearlyViaMonthly = monthlyDecimal.multiplying(by: 12)
        guard yearlyViaMonthly.doubleValue > 0 else { return nil }
        let savings = Int((1 - yearlyDecimal.doubleValue / yearlyViaMonthly.doubleValue) * 100)
        guard savings > 0 else { return nil }
        return L10n.formatted("premium_save_format", savings)
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }

    private func processPurchase(_ transaction: Transaction) async {
        guard let _ = ProductID(rawValue: transaction.productID) else {
            return
        }

        if transaction.revocationDate == nil {
            FeatureGate.currentTier = .premium
        }
    }


}

// MARK: - Product Display Helpers

extension Product {
    var displayPeriodTitle: String {
        guard type == .autoRenewable,
              let sub = subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month: return L10n.text("premium_per_month")
        case .year: return L10n.text("premium_per_year")
        case .week: return L10n.text("premium_per_week")
        default: return ""
        }
    }
}
