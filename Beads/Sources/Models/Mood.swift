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
}
