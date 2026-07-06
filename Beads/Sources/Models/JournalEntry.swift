import Foundation

/// A private, never-shared reflection. Sharing only ever happens via a separately
/// generated Ripple Card image — this record itself is never exposed to other users.
struct JournalEntry: Codable, Identifiable {
    static let maxTextLength = 60
    static let maxMoods = 2

    let id: UUID
    let date: Date
    var text: String
    var moods: [Mood]

    init(id: UUID = UUID(), date: Date = Date(), text: String = "", moods: [Mood] = []) {
        self.id = id
        self.date = date
        self.text = String(text.prefix(Self.maxTextLength))
        self.moods = Array(moods.prefix(Self.maxMoods))
    }
}
