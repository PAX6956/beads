import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var library: [ContentItem] = ContentLibrary.loadSeed()
    @State private var journalText: String = ""
    @State private var selectedMoods: Set<Mood> = []
    @State private var isShowingShareCard = false

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
                }
                .padding()
            }
            .navigationTitle("Today")
            .sheet(isPresented: $isShowingShareCard) {
                if let item = todayItem {
                    ShareCardSheet(text: item.quote)
                }
            }
        }
    }

    private func quoteCard(_ item: ContentItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.quote)
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
            store.markTodayComplete()
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
                .onChange(of: journalText) { newValue in
                    if newValue.count > JournalEntry.maxTextLength {
                        journalText = String(newValue.prefix(JournalEntry.maxTextLength))
                    }
                }
            Button("Save") {
                store.addJournalEntry(text: journalText, moods: Array(selectedMoods))
                journalText = ""
                selectedMoods = []
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
            }
        }
    }

    private func toggle(_ mood: Mood) {
        if selectedMoods.contains(mood) {
            selectedMoods.remove(mood)
        } else if selectedMoods.count < JournalEntry.maxMoods {
            selectedMoods.insert(mood)
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(PracticeStore())
}
