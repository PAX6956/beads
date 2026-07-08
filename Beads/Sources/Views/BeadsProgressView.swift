import SwiftUI

struct BeadsProgressView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var library: [ContentItem] = ContentLibrary.loadSeed()
    @State private var spinDistance: Double = 0

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        store.currentTierInfo
    }

    private var nextTier: BeadTier? {
        BeadTierLibrary.nextTier(after: store.growthValue, tiers: BeadTierLibrary.loadTiers())
    }

    private var cycleProgress: Int {
        store.beadCount % BeadRingView.ringCapacity
    }

    private var todayItem: ContentItem? {
        ContentLibrary.todayItem(from: library)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pushes the carousel down from the nav title so its
                    // drag area sits somewhere a thumb can comfortably reach
                    // while holding the phone one-handed, per user request.
                    // (Was 0.05, then 0.02, pulled up further each time after
                    // visual feedback that it read as too far down.)
                    Color.clear.frame(height: UIScreen.main.bounds.height * 0.0)

                    if let todayItem {
                        QuoteTickerView(item: todayItem, spinDistance: spinDistance)
                    }

                    if let tierInfo {
                        BeadCarouselView(
                            tier: tierInfo.tier,
                            beyondIntensity: tierInfo.beyondIntensity,
                            cycleProgress: cycleProgress,
                            onDistanceChange: { spinDistance = $0 }
                        )
                        VStack(spacing: 2) {
                            Text(tierInfo.tier.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Text(growthAnnotation)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("\(store.currentStreak) day streak")
                        .font(.largeTitle.weight(.bold))

                    ProgressView(value: store.progressToNextBead)
                        .padding(.horizontal)

                    Text("\(7 - Int(store.progressToNextBead * 7)) days to your next bead")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    HistoryCalendarView()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Beads")
        }
    }

    private var growthAnnotation: String {
        let growth = Int(store.growthValue)
        if let nextTier {
            let remaining = max(0, nextTier.thresholdDays - growth)
            return String(localized: "\(growth) growth days · \(remaining) to \(nextTier.localizedName)")
        }
        return String(localized: "\(growth) growth days")
    }
}

#Preview {
    BeadsProgressView()
        .environmentObject(PracticeStore())
}
