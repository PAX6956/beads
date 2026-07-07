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
    /// The quote/practice line that was showing when this entry was written —
    /// the whole point of a good line is that someone might be moved enough
    /// by it, in that moment, to write a few words of their own. Optional so
    /// entries synced from before this existed still decode fine.
    var associatedQuote: String?

    init(id: UUID = UUID(), date: Date = Date(), text: String = "", moods: [Mood] = [], associatedQuote: String? = nil) {
        self.id = id
        self.date = date
        self.text = String(text.prefix(Self.maxTextLength))
        self.moods = Array(moods.prefix(Self.maxMoods))
        self.associatedQuote = associatedQuote
    }
}
