import Foundation
import Combine
import CloudKit

/// The local JSON cache is the source of truth for the UI (instant, works offline).
/// CloudKit is a best-effort background sync layer on top of it: writes are pushed
/// after they land locally, and on launch we merge in anything written from the
/// user's other devices. If iCloud isn't signed in, the app just runs local-only.
@MainActor
final class PracticeStore: ObservableObject {
    @Published private(set) var practiceEntries: [PracticeEntry] = []
    @Published private(set) var journalEntries: [JournalEntry] = []

    private let practiceFileURL: URL
    private let journalFileURL: URL
    private let cloudSync = CloudSyncService()

    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        practiceFileURL = directory.appendingPathComponent("practice_entries.json")
        journalFileURL = directory.appendingPathComponent("journal_entries.json")
        practiceEntries = Self.load(from: practiceFileURL) ?? []
        journalEntries = Self.load(from: journalFileURL) ?? []
        Task { await syncWithCloud() }
    }

    /// Pulls down anything saved from other devices and merges it into the local
    /// cache by id. Safe to call repeatedly; does nothing if iCloud isn't available.
    func syncWithCloud() async {
        guard await cloudSync.accountStatus() == .available else { return }

        if let remotePractice = try? await cloudSync.fetchPracticeEntries() {
            mergePracticeEntries(remotePractice)
        }
        if let remoteJournal = try? await cloudSync.fetchJournalEntries() {
            mergeJournalEntries(remoteJournal)
        }
    }

    private func mergePracticeEntries(_ remote: [PracticeEntry]) {
        var byId = Dictionary(uniqueKeysWithValues: practiceEntries.map { ($0.id, $0) })
        for entry in remote { byId[entry.id] = entry }
        practiceEntries = byId.values.sorted { $0.date < $1.date }
        persist(practiceEntries, to: practiceFileURL)
    }

    private func mergeJournalEntries(_ remote: [JournalEntry]) {
        var byId = Dictionary(uniqueKeysWithValues: journalEntries.map { ($0.id, $0) })
        for entry in remote { byId[entry.id] = entry }
        journalEntries = byId.values.sorted { $0.date > $1.date }
        persist(journalEntries, to: journalFileURL)
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
        guard !hasCompletedToday() else { return }
        let entry = PracticeEntry(date: Date())
        practiceEntries.append(entry)
        persist(practiceEntries, to: practiceFileURL)
        pushToCloud(entry)
    }

    func makeUp(date: Date) {
        let calendar = Calendar.current
        guard !practiceEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) else { return }
        guard let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo <= 3, daysAgo > 0 else { return }
        let entry = PracticeEntry(date: date, wasMakeUp: true)
        practiceEntries.append(entry)
        persist(practiceEntries, to: practiceFileURL)
        pushToCloud(entry)
    }

    func addJournalEntry(text: String, moods: [Mood]) {
        let entry = JournalEntry(text: text, moods: moods)
        journalEntries.insert(entry, at: 0)
        persist(journalEntries, to: journalFileURL)
        pushToCloud(entry)
    }

    /// Fire-and-forget: the local write already happened, so a failed or slow
    /// push just means this device's copy is momentarily ahead of iCloud.
    private func pushToCloud(_ entry: PracticeEntry) {
        Task { try? await cloudSync.save(entry) }
    }

    private func pushToCloud(_ entry: JournalEntry) {
        Task { try? await cloudSync.save(entry) }
    }

    private func persist<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
