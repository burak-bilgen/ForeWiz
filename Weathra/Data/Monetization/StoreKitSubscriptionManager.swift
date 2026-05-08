import Combine
import Foundation
import StoreKit
import os

@MainActor
final class StoreKitSubscriptionManager: ObservableObject {
    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var isPremium: Bool { tier == .premium }

    private let productIDs: [String] = SubscriptionConfiguration.productIDs

    private var storeProducts: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    private let cacheKey = "cached_subscription_tier"
    private let logger = Logger(subsystem: "com.weathra.subscription", category: "StoreKitManager")

    init() {
        tier = loadCachedTier()
        let currentTier = tier
        logger.info("Subscription manager initialized with tier: \(currentTier.rawValue)")
        updateListenerTask = listenForTransactions()
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        logger.info("Loading products...")
        do {
            storeProducts = try await Product.products(for: productIDs)
            let mappedProducts = storeProducts
                .map { SubscriptionProduct(from: $0) }
                .sorted { lhs, rhs in
                    productSortIndex(lhs.id) < productSortIndex(rhs.id)
                }
            products = mappedProducts

            if mappedProducts.isEmpty {
                errorMessage = L10n.text("premium_product_not_found")
                logger.error("No StoreKit products returned for configured IDs")
            } else {
                logger.info("Products loaded successfully: \(mappedProducts.count) products")
            }
        } catch {
            let error = localizedError(error)
            errorMessage = error
            logger.error("Failed to load products: \(error)")
        }
        isLoading = false
    }

    func purchase(_ product: SubscriptionProduct) async -> Bool {
        guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
            errorMessage = L10n.text("premium_product_not_found")
            logger.error("Product not found: \(product.id)")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        logger.info("Starting purchase for product: \(product.id)")
        do {
            let result = try await storeProduct.purchase()
            switch result {
            case .success(let verification):
                logger.info("Purchase successful, handling verification")
                await handle(verification)
                return isPremium
            case .userCancelled:
                logger.info("Purchase cancelled by user")
                return false
            case .pending:
                errorMessage = L10n.text("premium_pending")
                logger.warning("Purchase pending")
                return false
            @unknown default:
                logger.warning("Unknown purchase result")
                return false
            }
        } catch {
            let error = localizedError(error)
            errorMessage = error
            logger.error("Purchase failed: \(error)")
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        logger.info("Restoring purchases...")
        do {
            try await AppStore.sync()
            await refreshStatus()
            let premiumStatus = isPremium
            logger.info("Purchases restored successfully, isPremium: \(premiumStatus)")
            return premiumStatus
        } catch {
            let error = localizedError(error)
            errorMessage = error
            logger.error("Failed to restore purchases: \(error)")
            return false
        }
    }

    func refreshStatus() async {
        logger.info("Refreshing subscription status...")
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if productIDs.contains(transaction.productID) && transaction.revocationDate == nil {
                tier = .premium
                saveCachedTier(.premium)
                logger.info("Active entitlement found for \(transaction.productID) — premium")
                return
            }
        }
        tier = .free
        saveCachedTier(.free)
        logger.info("No active entitlements found — free")
    }

    private func loadCachedTier() -> SubscriptionTier {
        guard let rawValue = UserDefaults.standard.string(forKey: cacheKey),
              let cached = SubscriptionTier(rawValue: rawValue) else {
            logger.debug("No cached tier found, defaulting to free")
            return .free
        }
        logger.debug("Loaded cached tier: \(cached.rawValue)")
        return cached
    }

    private func saveCachedTier(_ tier: SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: cacheKey)
        logger.debug("Saved cached tier: \(tier.rawValue)")
    }

    private func productSortIndex(_ id: String) -> Int {
        productIDs.firstIndex(of: id) ?? Int.max
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try result.payloadValue
            await transaction.finish()
            await refreshStatus()
            logger.info("Transaction handled successfully")
        } catch {
            logger.error("Failed to handle transaction: \(error.localizedDescription)")
        }
    }

    private func localizedError(_ error: Error) -> String {
        if let skError = error as? StoreKitError {
            switch skError {
            case .networkError:
                return L10n.text("premium_network_error")
            case .notAvailableInStorefront, .notEntitled:
                return error.localizedDescription
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

private extension SubscriptionProduct {
    init(from product: Product) {
        self.id = product.id
        self.displayName = product.displayName
        self.description = product.description
        self.price = product.displayPrice
        if let subscription = product.subscription {
            self.period = subscription.subscriptionPeriod.localizedDescription
        } else {
            self.period = ""
        }
        self.isPremium = true
    }
}

private extension Product.SubscriptionPeriod {
    var localizedDescription: String {
        switch unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return ""
        }
    }
}
