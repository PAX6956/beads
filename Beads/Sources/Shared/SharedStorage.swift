import Foundation

/// The single storage location both the main app and the widget extension read
/// and write — an App Group container, not each process's own sandboxed
/// Documents directory, so a tap in the widget and a tap in the app see the
/// same state without needing a separate sync mechanism between them.
enum SharedStorage {
    static let appGroupIdentifier = "group.com.beadsapp.beads"

    static func containerDirectory() -> URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var practiceFileURL: URL {
        containerDirectory().appendingPathComponent("practice_entries.json")
    }

    private static var journalFileURL: URL {
        containerDirectory().appendingPathComponent("journal_entries.json")
    }

    static func loadPracticeEntries() -> [PracticeEntry] {
        load(from: practiceFileURL) ?? []
    }

    static func savePracticeEntries(_ entries: [PracticeEntry]) {
        persist(entries, to: practiceFileURL)
    }

    static func loadJournalEntries() -> [JournalEntry] {
        load(from: journalFileURL) ?? []
    }

    static func saveJournalEntries(_ entries: [JournalEntry]) {
        persist(entries, to: journalFileURL)
    }

    /// Shared by the app's "Practice" button and the widget's tap-to-complete
    /// intent. Returns the new entry if one was recorded, or nil if today was
    /// already marked complete.
    @discardableResult
    static func markTodayComplete(calendar: Calendar = .current, today: Date = Date()) -> PracticeEntry? {
        var entries = loadPracticeEntries()
        guard !entries.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) else { return nil }
        let entry = PracticeEntry(date: today)
        entries.append(entry)
        savePracticeEntries(entries)
        return entry
    }

    /// Device-local only (not synced to CloudKit) — a minor growth-value input,
    /// not core data worth the complexity of syncing across devices.
    static func loadShareCount() -> Int {
        UserDefaults(suiteName: appGroupIdentifier)?.integer(forKey: "shareCount") ?? 0
    }

    static func incrementShareCount() {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        defaults?.set(loadShareCount() + 1, forKey: "shareCount")
    }

    private static func persist<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
