import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var entryToShare: JournalEntry?

    private var groupedByMonth: [(String, [JournalEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let groups = Dictionary(grouping: store.journalEntries) { formatter.string(from: $0.date) }
        return groups.sorted { lhs, rhs in
            (groups[lhs.key]?.first?.date ?? .distantPast) > (groups[rhs.key]?.first?.date ?? .distantPast)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.journalEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.0) { month, entries in
                            Section(month) {
                                ForEach(entries) { entry in
                                    entryRow(entry)
                                        .swipeActions {
                                            Button(role: .destructive) {
                                                Haptics.warning()
                                                store.deleteJournalEntry(entry)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(item: $entryToShare) { entry in
                ShareCardSheet(text: entry.text)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No reflections yet")
                .font(.headline)
            Text("Entries you save from Today will show up here — visible only to you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ForEach(entry.moods) { mood in
                    Text(mood.emoji)
                        .accessibilityLabel(mood.label)
                }
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let quote = entry.associatedQuote, !quote.isEmpty {
                Text(quote)
                    .font(.system(.callout, design: .serif).italic())
                    .foregroundStyle(.secondary)
            }
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.body)
                Button {
                    entryToShare = entry
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView()
        .environmentObject(PracticeStore())
}
