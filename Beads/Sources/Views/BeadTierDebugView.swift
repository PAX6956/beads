#if DEBUG
import SwiftUI

/// Lets you see every tier's actual on-device rendering without waiting years
/// to earn them — the offscreen macOS render used during development is a
/// useful first pass, but the real screen (OLED color, glow blending) is the
/// real check. DEBUG-only, reachable from Settings.
struct BeadTierDebugView: View {
    private let tiers = BeadTierLibrary.loadTiers()

    var body: some View {
        List(tiers) { tier in
            HStack(spacing: 16) {
                BeadRingView(lifetimeDays: tier.thresholdDays, cycleProgress: 8, size: 90)
                VStack(alignment: .leading) {
                    Text("\(tier.order). \(tier.name)")
                        .font(.headline)
                    Text("from day \(tier.thresholdDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Tier Preview")
    }
}

#Preview {
    NavigationStack {
        BeadTierDebugView()
    }
}
#endif
