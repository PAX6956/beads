import SwiftUI

struct BeadsProgressView: View {
    @EnvironmentObject private var store: PracticeStore

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        store.currentTierInfo
    }

    private var nextTier: BeadTier? {
        BeadTierLibrary.nextTier(after: store.growthValue, tiers: BeadTierLibrary.loadTiers())
    }

    private var cycleProgress: Int {
        store.beadCount % BeadRingView.ringCapacity
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let tierInfo {
                        BeadCarouselView(tier: tierInfo.tier, beyondIntensity: tierInfo.beyondIntensity, cycleProgress: cycleProgress)
                        VStack(spacing: 2) {
                            Text(tierInfo.tier.name)
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
            return "\(growth) growth days · \(remaining) to \(nextTier.name)"
        }
        return "\(growth) growth days"
    }
}

#Preview {
    BeadsProgressView()
        .environmentObject(PracticeStore())
}
