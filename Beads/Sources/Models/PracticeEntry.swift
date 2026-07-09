import Foundation

/// One row per calendar day the user marked "Done" (or made up via the catch-up flow).
struct PracticeEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let wasMakeUp: Bool

    init(id: UUID = UUID(), date: Date, wasMakeUp: Bool = false) {
        self.id = id
        self.date = date
        self.wasMakeUp = wasMakeUp
    }
}

/// Turns a set of practice dates into the "beads" visualization: one bead per 7-day streak.
enum BeadsProgress {
    static func currentStreak(entries: [PracticeEntry], calendar: Calendar = .current, today: Date = Date()) -> Int {
        let days = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: today)
        if !days.contains(cursor) {
            // Today not completed yet doesn't mean the streak is broken — it
            // stays alive until a full day is actually missed. Count from
            // yesterday instead; if yesterday's missing too this falls
            // through to 0 below, which is a real break.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    static func beadCount(forStreak streak: Int) -> Int {
        streak / 7
    }

    static func progressToNextBead(forStreak streak: Int) -> Double {
        Double(streak % 7) / 7.0
    }
}
