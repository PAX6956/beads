import SwiftUI

extension Color {
    /// Accepts "#RRGGBB" or "#RRGGBBAA".
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        if sanitized.count > 6 {
            let r = Double((value & 0xFF00_0000) >> 24) / 255
            let g = Double((value & 0x00FF_0000) >> 16) / 255
            let b = Double((value & 0x0000_FF00) >> 8) / 255
            let a = Double(value & 0x0000_00FF) / 255
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            let r = Double((value & 0xFF0000) >> 16) / 255
            let g = Double((value & 0x00FF00) >> 8) / 255
            let b = Double(value & 0x0000FF) / 255
            self.init(red: r, green: g, blue: b)
        }
    }
}
