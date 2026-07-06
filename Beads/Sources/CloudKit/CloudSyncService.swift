import CloudKit
import Foundation

enum CloudRecordType {
    static let practiceEntry = "PracticeEntry"
    static let journalEntry = "JournalEntry"
}

/// Thin wrapper around the private CloudKit database. Callers are expected to keep
/// a local cache as the source of truth for the UI and treat this as a best-effort
/// background sync — a single user's own data across their own devices, not a
/// realtime multi-user store, so simple "push on write, merge on launch" is enough.
actor CloudSyncService {
    private let container: CKContainer
    private let database: CKDatabase

    init(containerIdentifier: String = "iCloud.com.beadsapp.beads") {
        container = CKContainer(identifier: containerIdentifier)
        database = container.privateCloudDatabase
    }

    func accountStatus() async -> CKAccountStatus {
        (try? await container.accountStatus()) ?? .couldNotDetermine
    }

    func fetchPracticeEntries() async throws -> [PracticeEntry] {
        let query = CKQuery(recordType: CloudRecordType.practiceEntry, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        return matchResults.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return PracticeEntry(record: record)
        }
    }

    func fetchJournalEntries() async throws -> [JournalEntry] {
        let query = CKQuery(recordType: CloudRecordType.journalEntry, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)
        return matchResults.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return JournalEntry(record: record)
        }
    }

    func save(_ entry: PracticeEntry) async throws {
        _ = try await database.save(entry.asRecord())
    }

    func save(_ entry: JournalEntry) async throws {
        _ = try await database.save(entry.asRecord())
    }
}
