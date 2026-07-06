import Foundation

/// GDPR/CCPA "export my data" — a plain JSON dump of exactly what's stored,
/// nothing more. No account/profile data exists to include since there's no
/// server-side identity, just this device's (and iCloud's) copy of the two
/// record types.
enum DataExporter {
    private struct ExportPayload: Encodable {
        let exportedAt: Date
        let practiceEntries: [PracticeEntry]
        let journalEntries: [JournalEntry]
    }

    static func export(practiceEntries: [PracticeEntry], journalEntries: [JournalEntry]) -> URL? {
        let payload = ExportPayload(exportedAt: Date(), practiceEntries: practiceEntries, journalEntries: journalEntries)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(payload) else { return nil }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("beads-export-\(Int(Date().timeIntervalSince1970))")
            .appendingPathExtension("json")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
