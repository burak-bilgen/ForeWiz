import Combine
import Foundation
import StoreKit

@MainActor
final class StoreKitSubscriptionManager: ObservableObject {
    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    var isPremium: Bool { tier == .premium }

    private let productIDs: [String] = [
        "bilgenworks.weatherassistant.premium.monthly",
        "bilgenworks.weatherassistant.premium.yearly"
    ]

    private var storeProducts: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    private let cacheKey = "cached_subscription_tier"

    init() {
        tier = loadCachedTier()
        updateListenerTask = listenForTransactions()
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.map { SubscriptionProduct(from: $0) }
        } catch {
            errorMessage = localizedError(error)
        }
        isLoading = false
    }

    func purchase(_ product: SubscriptionProduct) async -> Bool {
        guard let storeProduct = storeProducts.first(where: { $0.id == product.id }) else {
            errorMessage = L10n.text( "premium_product_not_found")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await storeProduct.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
                return isPremium
            case .userCancelled:
                return false
            case .pending:
                errorMessage = L10n.text( "premium_pending")
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = localizedError(error)
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshStatus()
            return isPremium
        } catch {
            errorMessage = localizedError(error)
            return false
        }
    }

    func refreshStatus() async {
        do {
            let entitlements = try await Product.products(for: productIDs)
            for product in entitlements {
                guard let status = try await product.subscription?.status.first else { continue }
                if status.state == .subscribed || status.state == .inGracePeriod {
                    tier = .premium
                    saveCachedTier(.premium)
                    return
                }
            }
            tier = .free
            saveCachedTier(.free)
        } catch {
            tier = .free
        }
    }

    private func loadCachedTier() -> SubscriptionTier {
        guard let rawValue = UserDefaults.standard.string(forKey: cacheKey),
              let cached = SubscriptionTier(rawValue: rawValue) else {
            return .free
        }
        return cached
    }

    private func saveCachedTier(_ tier: SubscriptionTier) {
        UserDefaults.standard.set(tier.rawValue, forKey: cacheKey)
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
        } catch {
        }
    }

    private func localizedError(_ error: Error) -> String {
        if let skError = error as? StoreKitError {
            switch skError {
            case .networkError:
                return L10n.text( "premium_network_error")
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
