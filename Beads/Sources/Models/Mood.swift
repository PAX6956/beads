import Foundation

enum Mood: String, Codable, CaseIterable, Identifiable {
    case calm
    case restless
    case grateful
    case low
    case anxious
    case growing

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .restless: return "😤"
        case .grateful: return "🙏"
        case .low: return "😢"
        case .anxious: return "🔥"
        case .growing: return "🌱"
        }
    }

    var label: String {
        switch self {
        case .calm: return "Calm"
        case .restless: return "Restless"
        case .grateful: return "Grateful"
        case .low: return "Low"
        case .anxious: return "Anxious"
        case .growing: return "Growing"
        }
    }

    private var labelZh: String {
        switch self {
        case .calm: return "平静"
        case .restless: return "烦躁"
        case .grateful: return "感恩"
        case .low: return "低落"
        case .anxious: return "焦虑"
        case .growing: return "成长"
        }
    }

    /// Same `QuoteLanguagePreference` pattern as `ContentItem.localizedQuote`
    /// and `BeadTier.localizedName` — shown next to the emoji so the meaning
    /// isn't left to guesswork (🔥 reading as "Anxious" rather than "excited"
    /// is exactly the kind of thing that needs spelling out).
    var localizedLabel: String {
        QuoteLanguagePreference.current.wantsChinese ? labelZh : label
    }
}
