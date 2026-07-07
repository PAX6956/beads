import Foundation

/// One rung of the "patina" ladder — driven by lifetime cumulative practice
/// days, never resets on a broken streak. Deliberately data-driven (bundled
/// JSON, same pattern as the content library) rather than a hardcoded enum:
/// the ladder tops out at ~3 years today, but the whole point is that it
/// isn't supposed to have a real ceiling. Adding tier 12+ later is just
/// appending to bead_tiers.json in a future update, no logic changes needed.
struct BeadTier: Codable, Identifiable {
    let order: Int
    let name: String
    let thresholdDays: Int
    let baseColorHex: String
    let glowColorHex: String
    let glossiness: Double
    let sparkleIntensity: Double

    var id: Int { order }
}

enum BeadTierLibrary {
    static func loadTiers() -> [BeadTier] {
        guard let url = Bundle.main.url(forResource: "bead_tiers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tiers = try? JSONDecoder().decode([BeadTier].self, from: data) else {
            return []
        }
        return tiers.sorted { $0.thresholdDays < $1.thresholdDays }
    }

    /// `beyondIntensity` is 0 for anyone still within the defined ladder, and
    /// climbs slowly (never quite capping) once someone has out-lived every
    /// tier currently in the data file — the "no ceiling" piece made concrete.
    static func currentTier(lifetimeDays: Int, tiers: [BeadTier]) -> (tier: BeadTier, beyondIntensity: Double)? {
        guard let last = tiers.last else { return nil }
        let tier = tiers.last(where: { $0.thresholdDays <= lifetimeDays }) ?? tiers[0]

        guard tier.order == last.order, lifetimeDays > last.thresholdDays else {
            return (tier, 0)
        }
        let extraYears = Double(lifetimeDays - last.thresholdDays) / 365.0
        return (tier, min(1.0, extraYears / 10.0))
    }
}
