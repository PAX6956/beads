import SwiftUI

/// PRD requires a brief reflection to make up a missed day, rather than a bare
/// one-tap — keeps the streak mechanic from becoming trivially gameable.
struct MakeUpPracticeSheet: View {
    let date: Date

    @EnvironmentObject private var store: PracticeStore
    @Environment(\.dismiss) private var dismiss
    @State private var reflection = ""
    @State private var showGrowthPulse = false
    @State private var leveledUp = false

    private var quoteForDate: String? {
        ContentLibrary.todayItem(from: ContentLibrary.loadSeed(), date: date)?.quote
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's one thing that felt calm, even briefly, on \(date.formatted(date: .abbreviated, time: .omitted))?")
                    .font(.body)
                TextField("A short reflection", text: $reflection, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Spacer()
            }
            .padding()
            .navigationTitle("Make Up Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        let previousTier = store.currentTierInfo?.tier.order
                        store.makeUp(date: date)
                        store.addJournalEntry(text: reflection, moods: [], associatedQuote: quoteForDate, date: date)
                        Haptics.success()
                        leveledUp = previousTier != store.currentTierInfo?.tier.order
                        showGrowthPulse = true
                    }
                    .disabled(reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .growthPulse(isPresented: $showGrowthPulse, tier: store.currentTierInfo?.tier, beyondIntensity: store.currentTierInfo?.beyondIntensity ?? 0, leveledUp: leveledUp)
            .onChange(of: showGrowthPulse) { isPresented in
                if !isPresented { dismiss() }
            }
        }
    }
}

#Preview {
    MakeUpPracticeSheet(date: Date())
        .environmentObject(PracticeStore())
}
