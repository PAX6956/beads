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
                } else if purchases.productsLoadFailed {
                    // Offline or a genuine StoreKit misconfiguration both
                    // leave `products` empty with no thrown error to catch —
                    // without this, the paywall spun forever with no way
                    // out but "Close".
                    VStack(spacing: 10) {
                        Text("Couldn't load subscription details. Check your connection and try again.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Try Again") {
                            Task { await purchases.refresh() }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ProgressView()
                }

                Button("Restore Purchases") {
                    Task { await purchases.restore() }
                }
                .font(.footnote)

                if let errorMessage {
                    Text(LocalizedStringKey(errorMessage))
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                // Required on any subscription purchase screen (App Review
                // Guideline 3.1.2) — auto-renewal terms live in Terms of Use,
                // full data handling in Privacy Policy.
                HStack(spacing: 6) {
                    Link("Terms of Use", destination: URL(string: "https://pax6956.github.io/beads-legal/terms-of-use.html")!)
                    Text("·")
                    Link("Privacy Policy", destination: URL(string: "https://pax6956.github.io/beads-legal/privacy-policy.html")!)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

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
