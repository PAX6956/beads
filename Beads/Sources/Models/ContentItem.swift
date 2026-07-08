import Foundation

/// Independent of the system/UI language: plenty of bilingual users keep
/// their phone's system language in English while reading/writing Chinese
/// day to day, and the rest of the app's UI isn't translated yet, so tying
/// quote language to system locale would both miss those users and produce
/// an English-UI/Chinese-quote mismatch for anyone who *did* switch. `.system`
/// is just the default starting guess, not a hard binding.
enum QuoteLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case english
    case chinese

    var id: String { rawValue }

    static let storageKey = "quoteLanguagePreference"

    static var current: QuoteLanguagePreference {
        QuoteLanguagePreference(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    var displayName: String {
        switch self {
        case .system: return "Match System"
        case .english: return "English"
        case .chinese: return "中文"
        }
    }

    var wantsChinese: Bool {
        switch self {
        case .system: return Locale.current.language.languageCode?.identifier == "zh"
        case .english: return false
        case .chinese: return true
        }
    }
}

struct ContentItem: Codable, Identifiable {
    let id: Int
    let quote: String
    let sourceNote: String
    let microAction: String
    let tags: [String]
    let quoteZh: String?

    var localizedQuote: String {
        guard QuoteLanguagePreference.current.wantsChinese, let quoteZh else { return quote }
        return quoteZh
    }
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
