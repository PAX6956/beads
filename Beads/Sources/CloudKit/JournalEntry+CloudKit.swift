import CloudKit

extension JournalEntry {
    init?(record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date,
              let text = record["text"] as? String else { return nil }
        let moodsRaw = record["moods"] as? [String] ?? []
        let moods = moodsRaw.compactMap { Mood(rawValue: $0) }
        let associatedQuote = record["associatedQuote"] as? String
        self.init(id: id, date: date, text: text, moods: moods, associatedQuote: associatedQuote)
    }

    func asRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudRecordType.journalEntry, recordID: CKRecord.ID(recordName: id.uuidString))
        record["id"] = id.uuidString
        record["date"] = date
        record["text"] = text
        record["moods"] = moods.map(\.rawValue)
        record["associatedQuote"] = associatedQuote
        return record
    }
}
