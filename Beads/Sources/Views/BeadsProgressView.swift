import SwiftUI

struct BeadsProgressView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var library: [ContentItem] = ContentLibrary.loadSeed()
    @State private var spinDistance: Double = 0
    // Fed into `.id()` on the bits of the layout that show localized text
    // below, to force them to re-render when Quote Language changes in
    // Settings — `.localizedQuote`/`.localizedName` read UserDefaults through
    // a plain static property, which isn't a SwiftUI-tracked dependency on
    // its own, and declaring-but-never-reading an @AppStorage property alone
    // wasn't enough to trigger a re-render in testing. Applied narrowly
    // (not to the whole VStack) so it doesn't also reset BeadCarouselView's
    // own spin state every time the language changes.
    @AppStorage(QuoteLanguagePreference.storageKey) private var quoteLanguageTrigger: String = QuoteLanguagePreference.system.rawValue

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        store.currentTierInfo
    }

    private var nextTier: BeadTier? {
        BeadTierLibrary.nextTier(after: store.growthValue, tiers: BeadTierLibrary.loadTiers())
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
                            onDistanceChange: { spinDistance = $0 }
                        )
                        VStack(spacing: 2) {
                            Text(tierInfo.tier.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Text(growthAnnotation)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .id(quoteLanguageTrigger)
                    }

                    Text("\(store.currentStreak) day streak")
                        .font(.largeTitle.weight(.bold))

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
