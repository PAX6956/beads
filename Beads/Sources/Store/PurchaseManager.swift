import Foundation
import StoreKit

/// Thin StoreKit 2 wrapper gating the paid perks (custom photo Ripple Card
/// backgrounds, the extra template styles). One auto-renewable subscription,
/// no server: `Transaction.currentEntitlements` is Apple's own receipt of
/// truth, so there's nothing to sync or host ourselves.
@MainActor
final class PurchaseManager: ObservableObject {
    static let proMonthlyProductID = "com.beadsapp.beads.pro.monthly"

    @Published private(set) var isPro = false
    @Published private(set) var products: [Product] = []

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refresh() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refresh() async {
        products = (try? await Product.products(for: [Self.proMonthlyProductID])) ?? []
        await updateEntitlement()
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        if case .success(let verification) = result {
            await handle(verification)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await updateEntitlement()
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        await transaction.finish()
        await updateEntitlement()
    }

    private func updateEntitlement() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Self.proMonthlyProductID {
                hasPro = true
            }
        }
        isPro = hasPro
    }
}
