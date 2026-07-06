import Foundation
import Combine

/// Local-only persistence for the MVP. CloudKit sync will replace the file-backed
/// storage once the iCloud container is provisioned in App Store Connect —
/// the public interface here is meant to stay stable across that swap.
@MainActor
final class PracticeStore: ObservableObject {
    @Published private(set) var practiceEntries: [PracticeEntry] = []
    @Published private(set) var journalEntries: [JournalEntry] = []

    private let practiceFileURL: URL
    private let journalFileURL: URL

    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) {
        practiceFileURL = directory.appendingPathComponent("practice_entries.json")
        journalFileURL = directory.appendingPathComponent("journal_entries.json")
        practiceEntries = Self.load(from: practiceFileURL) ?? []
        journalEntries = Self.load(from: journalFileURL) ?? []
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
        practiceEntries.append(PracticeEntry(date: Date()))
        persist(practiceEntries, to: practiceFileURL)
    }

    func makeUp(date: Date) {
        let calendar = Calendar.current
        guard !practiceEntries.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) else { return }
        guard let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day, daysAgo <= 3, daysAgo > 0 else { return }
        practiceEntries.append(PracticeEntry(date: date, wasMakeUp: true))
        persist(practiceEntries, to: practiceFileURL)
    }

    func addJournalEntry(text: String, moods: [Mood]) {
        let entry = JournalEntry(text: text, moods: moods)
        journalEntries.insert(entry, at: 0)
        persist(journalEntries, to: journalFileURL)
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
