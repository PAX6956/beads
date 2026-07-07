import SwiftUI

struct BeadsProgressView: View {
    @EnvironmentObject private var store: PracticeStore

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        BeadTierLibrary.currentTier(lifetimeDays: store.practiceEntries.count, tiers: BeadTierLibrary.loadTiers())
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
                        Text(tierInfo.tier.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
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
}

#Preview {
    BeadsProgressView()
        .environmentObject(PracticeStore())
}
