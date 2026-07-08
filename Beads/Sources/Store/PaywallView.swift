import SwiftUI
import StoreKit

/// Shown wherever a Pro-only perk is tapped without an active subscription —
/// currently just the Ripple Card's custom-photo background. Kept generic
/// (no reference to "photo") so the same sheet can gate future perks too.
struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)
                    .padding(.top, 24)

                Text("Beads Pro")
                    .font(.title2.weight(.semibold))

                Text("Use your own photos as Ripple Card backgrounds, plus extra card styles.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                Spacer(minLength: 12)

                if let product = purchases.products.first {
                    Button {
                        purchase(product)
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                            } else {
                                Text("Subscribe — \(product.displayPrice)/month")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(isPurchasing)
                } else {
                    ProgressView()
                }

                Button("Restore Purchases") {
                    Task { await purchases.restore() }
                }
                .font(.footnote)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await purchases.refresh() }
        .onChange(of: purchases.isPro) { isPro in
            if isPro { dismiss() }
        }
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await purchases.purchase(product)
            } catch {
                errorMessage = "Something went wrong. Please try again."
            }
            isPurchasing = false
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
