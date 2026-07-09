import SwiftUI
#if DEBUG
import UserNotifications
#endif

struct TodayView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var library: [ContentItem] = ContentLibrary.loadSeed()
    // Its only job is forcing this view to re-render when the Quote Language
    // setting changes elsewhere: `.localizedQuote` reads UserDefaults through
    // a plain static property, which isn't a SwiftUI-tracked dependency on
    // its own. Fed into `.id()` below rather than just declared — SwiftUI
    // only seems to register an @AppStorage/@State dependency for properties
    // actually *read* during body, and declaring-but-never-reading one
    // wasn't enough to trigger a re-render in testing.
    @AppStorage(QuoteLanguagePreference.storageKey) private var quoteLanguageTrigger: String = QuoteLanguagePreference.system.rawValue
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
                    takeAMomentRow
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
                .id(quoteLanguageTrigger)
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
                        // `.labelStyle(.titleAndIcon)` does not reliably show
                        // the title text here — .topBarTrailing collapses to
                        // icon-only regardless of that hint (confirmed on
                        // device, not just a theoretical iOS quirk). The
                        // real fix for "no guidance" is takeAMomentRow below,
                        // in the main content where a real label fits; this
                        // stays icon-only as a fast repeat-access shortcut.
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
                HStack(alignment: .bottom, spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
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

    // The toolbar icon alone couldn't show its own label (see the comment on
    // that ToolbarItem) — this is the actual "what is this and why" entry
    // point, living in the main content where a real title + subtitle fit.
    private var takeAMomentRow: some View {
        Button {
            Haptics.lightTap()
            isShowingMoment = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wind")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Take a moment")
                        .font(.subheadline.weight(.semibold))
                    Text("A one-minute breathing pause, any time you need it")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 6) {
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
            // What an emoji "means" isn't always obvious at a glance (🔥
            // reading as "excited" rather than "Anxious," say) — spelling
            // it out for whatever's currently selected removes the guesswork.
            if !selectedMoods.isEmpty {
                Text(Mood.allCases.filter(selectedMoods.contains).map(\.localizedLabel).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            removeEmojiPrefix(mood.emoji)
        } else if selectedMoods.count < JournalEntry.maxMoods {
            selectedMoods.insert(mood)
            addEmojiPrefix(mood.emoji)
        }
        Haptics.lightTap()
    }

    // Selecting a mood drops its emoji into the reflection field automatically
    // — no need to separately type out how you're feeling after you've
    // already tapped it. Prefixed (not appended) so it reads "😌 <reflection>"
    // the way a quick mood-tagged note naturally would.
    private func addEmojiPrefix(_ emoji: String) {
        guard !journalText.contains(emoji) else { return }
        journalText = journalText.isEmpty ? emoji : "\(emoji) \(journalText)"
    }

    private func removeEmojiPrefix(_ emoji: String) {
        journalText = journalText.replacingOccurrences(of: "\(emoji) ", with: "")
        journalText = journalText.replacingOccurrences(of: emoji, with: "")
    }
}

#Preview {
    TodayView()
        .environmentObject(PracticeStore())
}
