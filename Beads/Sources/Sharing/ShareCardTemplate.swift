import SwiftUI

/// Free tier ships the first 3; the remaining 5 are a subscription perk,
/// gated the same way the custom-photo background is (see `PurchaseManager`).
enum ShareCardTemplate: String, CaseIterable, Identifiable {
    case inkWash
    case minimalWhite
    case sunsetGradient
    case forestDusk
    case oceanDepth
    case roseQuartz
    case goldenHour
    case eclipse

    var id: String { rawValue }

    var isPro: Bool {
        switch self {
        case .inkWash, .minimalWhite, .sunsetGradient: return false
        case .forestDusk, .oceanDepth, .roseQuartz, .goldenHour, .eclipse: return true
        }
    }

    var displayName: String {
        switch self {
        case .inkWash: return "Ink Wash"
        case .minimalWhite: return "Minimal White"
        case .sunsetGradient: return "Sunset"
        case .forestDusk: return "Forest Dusk"
        case .oceanDepth: return "Ocean Depth"
        case .roseQuartz: return "Rose Quartz"
        case .goldenHour: return "Golden Hour"
        case .eclipse: return "Eclipse"
        }
    }

    var background: LinearGradient {
        switch self {
        case .inkWash:
            return LinearGradient(colors: [Color(white: 0.16), Color(white: 0.38)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimalWhite:
            return LinearGradient(colors: [Color(white: 0.99), Color(white: 0.93)],
                                   startPoint: .top, endPoint: .bottom)
        case .sunsetGradient:
            return LinearGradient(colors: [Color(red: 0.97, green: 0.69, blue: 0.45), Color(red: 0.70, green: 0.31, blue: 0.46)],
                                   startPoint: .top, endPoint: .bottom)
        case .forestDusk:
            return LinearGradient(colors: [Color(red: 0.11, green: 0.24, blue: 0.18), Color(red: 0.03, green: 0.08, blue: 0.07)],
                                   startPoint: .top, endPoint: .bottom)
        case .oceanDepth:
            return LinearGradient(colors: [Color(red: 0.09, green: 0.27, blue: 0.42), Color(red: 0.02, green: 0.09, blue: 0.18)],
                                   startPoint: .top, endPoint: .bottom)
        case .roseQuartz:
            return LinearGradient(colors: [Color(red: 0.96, green: 0.85, blue: 0.87), Color(red: 0.87, green: 0.80, blue: 0.92)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        case .goldenHour:
            return LinearGradient(colors: [Color(red: 0.98, green: 0.80, blue: 0.42), Color(red: 0.62, green: 0.35, blue: 0.14)],
                                   startPoint: .top, endPoint: .bottom)
        case .eclipse:
            return LinearGradient(colors: [Color(red: 0.10, green: 0.07, blue: 0.16), Color(red: 0.02, green: 0.01, blue: 0.05)],
                                   startPoint: .top, endPoint: .bottom)
        }
    }

    var textColor: Color {
        switch self {
        case .inkWash: return .white
        case .minimalWhite: return .black
        case .sunsetGradient: return .white
        case .forestDusk: return .white
        case .oceanDepth: return .white
        case .roseQuartz: return .black
        case .goldenHour: return .black
        case .eclipse: return .white
        }
    }
}
