import Foundation
import Combine
import CloudKit

/// The shared App Group storage (see SharedStorage) is the source of truth for
/// the UI (instant, works offline, and is the same file the widget's tap-to-
/// complete intent writes to). CloudKit is a best-effort background sync layer
/// on top of it: writes are pushed after they land locally, and on launch we
/// merge in anything written from the user's other devices — or from the
/// widget, which writes locally but can't reach CloudKit itself.
@MainActor
final class PracticeStore: ObservableObject {
    @Published private(set) var practiceEntries: [PracticeEntry] = []
    @Published private(set) var journalEntries: [JournalEntry] = []
    @Published private(set) var shareCount: Int = SharedStorage.loadShareCount()

    private let cloudSync = CloudSyncService()

    init() {
        practiceEntries = SharedStorage.loadPracticeEntries()
        journalEntries = SharedStorage.loadJournalEntries()
        Task { await syncWithCloud() }
    }

    /// Practice, journaling, and sharing all move the bracelet forward — practice
    /// is worth a full day since it's the core habit, journaling and sharing are
    /// smaller bonuses so someone who reflects or shares often sees their string
    /// change a bit faster without practice itself feeling secondary.
    var growthValue: Double {
        Double(practiceEntries.count)
            + Double(journalEntries.count) * 0.3
            + Double(shareCount) * 0.2
    }

    func recordShare() {
        SharedStorage.incrementShareCount()
        shareCount = SharedStorage.loadShareCount()
    }

    var currentTierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        BeadTierLibrary.currentTier(growthValue: growthValue, tiers: BeadTierLibrary.loadTiers())
    }

    /// Call when the app returns to the foreground so a completion recorded by
    /// the widget while the app wasn't running shows up immediately.
    func refreshFromDisk() {
        practiceEntries = SharedStorage.loadPracticeEntries()
        journalEntries = SharedStorage.loadJournalEntries()
    }

    /// Pulls down anything saved from other devices and merges it into the local
    /// cache by id, then pushes anything local CloudKit doesn't have yet (that
    /// includes entries the widget wrote directly to shared storage). Safe to
    /// call repeatedly; does nothing if iCloud isn't available.
    func syncWithCloud() async {
        guard await cloudSync.accountStatus() == .available else { return }

        if let remotePractice = try? await cloudSync.fetchPracticeEntries() {
            mergePracticeEntries(remotePractice)
            await pushMissing(practiceEntries, remoteIds: Set(remotePractice.map(\.id)))
        }
        if let remoteJournal = try? await cloudSync.fetchJournalEntries() {
            mergeJournalEntries(remoteJournal)
            await pushMissing(journalEntries, remoteIds: Set(remoteJournal.map(\.id)))
        }
    }

    private func pushMissing(_ local: [PracticeEntry], remoteIds: Set<UUID>) async {
        for entry in local where !remoteIds.contains(entry.id) {
            try? await cloudSync.save(entry)
        }
    }

    private func pushMissing(_ local: [JournalEntry], remoteIds: Set<UUID>) async {
        for entry in local where !remoteIds.contains(entry.id) {
            try? await cloudSync.save(entry)
        }
    }

    private func mergePracticeEntries(_ remote: [PracticeEntry]) {
        var byId = Dictionary(uniqueKeysWithValues: practiceEntries.map { ($0.id, $0) })
        for entry in remote { byId[entry.id] = entry }
        practiceEntries = byId.values.sorted { $0.date < $1.date }
        SharedStorage.savePracticeEntries(practiceEntries)
    }

    private func mergeJournalEntries(_ remote: [JournalEntry]) {
        var byId = Dictionary(uniqueKeysWithValues: journalEntries.map { ($0.id, $0) })
        for entry in remote { byId[entry.id] = entry }
        journalEntries = byId.values.sorted { $0.date > $1.date }
        SharedStorage.saveJournalEntries(journalEntries)
    }

    var currentStreak: Int {
        BeadsProgress.currentStreak(entries: practiceEntries)
    }

    var beadCount: Int {
        BeadsProgress.beadCount(forStreak: currentStreak)
    }

    var progressToNextBead: Double {
        BeadsProgress.progressToNextBead(forStreak: currentStreak)
    }

    func hasCompletedToday(calendar: Calendar = .current, today: Date = Date()) -> Bool {
        practiceEntries.contains { calendar.isDate($0.date, inSameDayAs: today) }
    }

    func markTodayComplete() {
        guard let entry = SharedStorage.markTodayComplete() else { return }
        practiceEntries.append(entry)
        pushToCloud(entry)
        NotificationScheduler.cancelReminder()
    }

    func makeUp(date: Date) {
        let calendar = Calendar.current
        guard !practiceEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) else { return }
        guard let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo <= 3, daysAgo > 0 else { return }
        let entry = PracticeEntry(date: date, wasMakeUp: true)
        practiceEntries.append(entry)
        SharedStorage.savePracticeEntries(practiceEntries)
        pushToCloud(entry)
    }

    func addJournalEntry(text: String, moods: [Mood], associatedQuote: String? = nil, date: Date = Date()) {
        let entry = JournalEntry(date: date, text: text, moods: moods, associatedQuote: associatedQuote)
        journalEntries.insert(entry, at: 0)
        SharedStorage.saveJournalEntries(journalEntries)
        pushToCloud(entry)
    }

    func deleteJournalEntry(_ entry: JournalEntry) {
        journalEntries.removeAll { $0.id == entry.id }
        SharedStorage.saveJournalEntries(journalEntries)
        Task { try? await cloudSync.delete(entry) }
    }

    func exportDataFile() -> URL? {
        DataExporter.export(practiceEntries: practiceEntries, journalEntries: journalEntries)
    }

    /// Clears local storage, cancels notifications, and best-effort deletes the
    /// CloudKit copy. If CloudKit deletion fails (offline, etc.) the local wipe
    /// still goes through — the stale remote records get cleaned up the next
    /// time this runs successfully, since local is empty and nothing re-pushes them.
    func deleteAllData() async {
        practiceEntries = []
        journalEntries = []
        SharedStorage.savePracticeEntries([])
        SharedStorage.saveJournalEntries([])
        NotificationScheduler.cancelAll()

        if await cloudSync.accountStatus() == .available {
            try? await cloudSync.deleteAllPracticeEntries()
            try? await cloudSync.deleteAllJournalEntries()
        }
    }

    /// Fire-and-forget: the local write already happened, so a failed or slow
    /// push just means this device's copy is momentarily ahead of iCloud.
    private func pushToCloud(_ entry: PracticeEntry) {
        Task { try? await cloudSync.save(entry) }
    }

    private func pushToCloud(_ entry: JournalEntry) {
        Task { try? await cloudSync.save(entry) }
    }
}
