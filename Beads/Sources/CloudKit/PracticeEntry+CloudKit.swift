import CloudKit

extension PracticeEntry {
    init?(record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date else { return nil }
        let wasMakeUp = (record["wasMakeUp"] as? Int64 ?? 0) == 1
        self.init(id: id, date: date, wasMakeUp: wasMakeUp)
    }

    func asRecord() -> CKRecord {
        let record = CKRecord(recordType: CloudRecordType.practiceEntry, recordID: CKRecord.ID(recordName: id.uuidString))
        record["id"] = id.uuidString
        record["date"] = date
        record["wasMakeUp"] = (wasMakeUp ? 1 : 0) as Int64
        return record
    }
}
