import SwiftUI

/// Free tier ships 3 templates per the pricing plan in beans_v2.md; the remaining
/// 5 are a subscription perk to add once paywalls exist.
enum ShareCardTemplate: String, CaseIterable, Identifiable {
    case inkWash
    case minimalWhite
    case sunsetGradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inkWash: return "Ink Wash"
        case .minimalWhite: return "Minimal White"
        case .sunsetGradient: return "Sunset"
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
        }
    }

    var textColor: Color {
        switch self {
        case .inkWash: return .white
        case .minimalWhite: return .black
        case .sunsetGradient: return .white
        }
    }
}
