import Foundation

struct ContentItem: Codable, Identifiable {
    let id: Int
    let quote: String
    let sourceNote: String
    let microAction: String
    let tags: [String]
}

struct ContentLibrary {
    static func loadSeed() -> [ContentItem] {
        guard let url = Bundle.main.url(forResource: "seed_practices", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([ContentItem].self, from: data) else {
            return []
        }
        return items
    }

    static func todayItem(from items: [ContentItem], calendar: Calendar = .current, date: Date = Date()) -> ContentItem? {
        guard !items.isEmpty else { return nil }
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % items.count
        return items[index]
    }
}
