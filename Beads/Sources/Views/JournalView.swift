import SwiftUI
import LocalAuthentication

struct JournalView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var entryToShare: JournalEntry?
    @AppStorage("journalLockEnabled") private var journalLockEnabled = false
    // Not persisted on purpose — every fresh appearance of this tab (and
    // every return from the background) should re-lock, otherwise the lock
    // would only ever matter once per app launch.
    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @Environment(\.scenePhase) private var scenePhase

    // Regenerated on every body evaluation — cheap (plain text, no image
    // rendering) so there's no need to cache it, and this keeps the
    // toolbar button a one-tap ShareLink instead of "generate, then share."
    private var exportDocumentURL: URL? {
        JournalExporter.exportMarkdown(store.journalEntries)
    }

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
                if journalLockEnabled && !isUnlocked {
                    lockedState
                } else if store.journalEntries.isEmpty {
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
            .toolbar {
                if (!journalLockEnabled || isUnlocked), !store.journalEntries.isEmpty, let exportDocumentURL {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: exportDocumentURL) {
                            Image(systemName: "doc.text")
                        }
                        .accessibilityLabel("Export Journal as a document")
                        .simultaneousGesture(TapGesture().onEnded { Haptics.lightTap() })
                    }
                }
            }
            .sheet(item: $entryToShare) { entry in
                ShareCardSheet(text: entry.text)
            }
        }
        .onAppear { authenticateIfNeeded() }
        // Re-lock on backgrounding even if this tab never actually
        // disappears (e.g. the user backgrounds the app while already on
        // Journal) — otherwise the lock only guards the initial tab switch.
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                isUnlocked = false
            }
        }
    }

    private var lockedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Journal is locked")
                .font(.headline)
            Button("Unlock") { authenticateIfNeeded() }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func authenticateIfNeeded() {
        guard journalLockEnabled, !isUnlocked, !isAuthenticating else { return }
        let context = LAContext()
        var error: NSError?
        // No biometrics or passcode set up at all — nothing to challenge
        // against, so don't lock someone out of their own journal with no
        // way back in.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = true
            return
        }
        isAuthenticating = true
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: String(localized: "Unlock your Journal")) { success, _ in
            DispatchQueue.main.async {
                isUnlocked = success
                isAuthenticating = false
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
                    // A plain HStack instead of Label — Label's built-in
                    // icon/text layout doesn't expose spacing control, and
                    // read as visually mismatched (icon and text looked
                    // like different sizes with an awkward gap). The same
                    // .font() on both keeps the SF Symbol and the text at
                    // matching scale and baseline.
                    HStack(alignment: .bottom, spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline.weight(.semibold))
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
