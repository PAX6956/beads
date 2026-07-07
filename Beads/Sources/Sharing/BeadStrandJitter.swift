import SwiftUI

/// The same bead texture gets reused for every position in a strand, so
/// without this every instance would look identically "stamped." A small,
/// stable-per-index rotation breaks that up cheaply — no extra art needed,
/// and it's deterministic (same index always yields the same angle) so it
/// doesn't jitter between renders or app launches.
enum BeadStrandJitter {
    static func rotation(for index: Int) -> Angle {
        .degrees(Double((index * 47) % 29) - 14)
    }
}
