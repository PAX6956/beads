import SwiftUI
#if DEBUG
import UserNotifications
#endif

struct TodayView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var library: [ContentItem] = ContentLibrary.loadSeed()
    @State private var journalText: String = ""
    @State private var selectedMoods: Set<Mood> = []
    @State private var isShowingShareCard = false
    @State private var isShowingMoment = false
    @State private var showGrowthPulse = false
    @State private var leveledUp = false
    @FocusState private var isJournalFieldFocused: Bool
    #if DEBUG
    @State private var pendingNotificationsSummary: String = "Loading…"
    #endif

    private var todayItem: ContentItem? {
        ContentLibrary.todayItem(from: library)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let item = todayItem {
                        quoteCard(item)
                    }
                    practiceButton
                    Divider()
                    quickJournalSection
                    #if DEBUG
                    Divider()
                    Text(pendingNotificationsSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .task { pendingNotificationsSummary = await Self.debugNotificationSummary() }
                    #endif
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isJournalFieldFocused = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.lightTap()
                        isShowingMoment = true
                    } label: {
                        Label("Take a moment", systemImage: "wind")
                    }
                }
            }
            .sheet(isPresented: $isShowingShareCard) {
                if let item = todayItem {
                    ShareCardSheet(text: item.localizedQuote)
                }
            }
            .fullScreenCover(isPresented: $isShowingMoment) {
                TakeAMomentView()
            }
            .growthPulse(isPresented: $showGrowthPulse, tier: store.currentTierInfo?.tier, beyondIntensity: store.currentTierInfo?.beyondIntensity ?? 0, leveledUp: leveledUp)
        }
    }

    /// Callers capture `store.currentTierInfo?.tier.order` *before* the action
    /// that changes growthValue, then pass it here right after — comparing to
    /// the (now-updated) current tier tells us whether this specific action
    /// was the one that tipped the bracelet into a new material.
    private func pulseGrowth(previousTierOrder: Int?) {
        leveledUp = previousTierOrder != store.currentTierInfo?.tier.order
        showGrowthPulse = true
    }

    private func quoteCard(_ item: ContentItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.localizedQuote)
                .font(.title3.weight(.medium))
            Text("Today's practice")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(item.microAction)
                .font(.body)
            Button {
                isShowingShareCard = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.caption.weight(.semibold))
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var practiceButton: some View {
        Button {
            let previousTier = store.currentTierInfo?.tier.order
            store.markTodayComplete()
            Haptics.success()
            pulseGrowth(previousTierOrder: previousTier)
        } label: {
            Label(store.hasCompletedToday() ? "Done for today" : "Practice",
                  systemImage: store.hasCompletedToday() ? "checkmark.circle.fill" : "circle")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.hasCompletedToday())
    }

    private var quickJournalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.subheadline.weight(.semibold))
            moodPicker
            TextField("A short reflection (optional)", text: $journalText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isJournalFieldFocused)
                .onChange(of: journalText) { newValue in
                    if newValue.count > JournalEntry.maxTextLength {
                        journalText = String(newValue.prefix(JournalEntry.maxTextLength))
                    }
                }
            Button("Save") {
                let previousTier = store.currentTierInfo?.tier.order
                store.addJournalEntry(text: journalText, moods: Array(selectedMoods), associatedQuote: todayItem?.localizedQuote)
                journalText = ""
                selectedMoods = []
                isJournalFieldFocused = false
                Haptics.lightTap()
                pulseGrowth(previousTierOrder: previousTier)
            }
            .disabled(journalText.isEmpty && selectedMoods.isEmpty)
        }
    }

    private var moodPicker: some View {
        HStack {
            ForEach(Mood.allCases) { mood in
                Button {
                    toggle(mood)
                } label: {
                    Text(mood.emoji)
                        .font(.title2)
                        .padding(8)
                        .background(selectedMoods.contains(mood) ? Color.accentColor.opacity(0.2) : .clear, in: Circle())
                }
                .accessibilityLabel(mood.label)
            }
        }
    }

    #if DEBUG
    private static func debugNotificationSummary() async -> String {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard !requests.isEmpty else { return "[Debug] 0 notifications scheduled" }
        let nextDates = requests.compactMap { request -> Date? in
            (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
        }.sorted()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        let nextThree = nextDates.prefix(3).map { formatter.string(from: $0) }.joined(separator: " · ")
        return "[Debug] \(requests.count) scheduled — next: \(nextThree)"
    }
    #endif

    private func toggle(_ mood: Mood) {
        if selectedMoods.contains(mood) {
            selectedMoods.remove(mood)
        } else if selectedMoods.count < JournalEntry.maxMoods {
            selectedMoods.insert(mood)
        }
        Haptics.lightTap()
    }
}

#Preview {
    TodayView()
        .environmentObject(PracticeStore())
}
