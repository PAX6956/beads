import Foundation

/// One rung of the "patina" ladder — driven by lifetime cumulative growth
/// value, never resets on a broken streak. Deliberately data-driven (bundled
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
    let nameZh: String?

    var id: Int { order }

    /// Same `QuoteLanguagePreference` that governs the daily quote — a tier
    /// name shown next to a Chinese quote in English would be the same
    /// language-mismatch problem that preference already exists to avoid.
    var localizedName: String {
        guard QuoteLanguagePreference.current.wantsChinese, let nameZh else { return name }
        return nameZh
    }

    /// Looks up "BeadTier1" ... "BeadTier11" in the asset catalog. Returns nil
    /// (callers fall back to the procedural placeholder) until the real image
    /// for that tier has actually been added — swapping in one tier's art at
    /// a time doesn't require touching any other tier or any code.
    var assetName: String { "BeadTier\(order)" }
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

    /// `growthValue` is a blend of practice/journaling/sharing (see
    /// PracticeStore.growthValue) — thresholds are still expressed in
    /// "day equivalents" since practice is the dominant contributor, but
    /// journaling and sharing let someone nudge past a threshold a little
    /// sooner. `beyondIntensity` is 0 for anyone still within the defined
    /// ladder, and climbs slowly (never quite capping) once someone has
    /// out-grown every tier currently in the data file — the "no ceiling"
    /// piece made concrete.
    static func currentTier(growthValue: Double, tiers: [BeadTier]) -> (tier: BeadTier, beyondIntensity: Double)? {
        guard let last = tiers.last else { return nil }
        let tier = tiers.last(where: { Double($0.thresholdDays) <= growthValue }) ?? tiers[0]

        guard tier.order == last.order, growthValue > Double(last.thresholdDays) else {
            return (tier, 0)
        }
        let extraYears = (growthValue - Double(last.thresholdDays)) / 365.0
        return (tier, min(1.0, extraYears / 10.0))
    }

    /// The next tier to reach, if any — used for the "N to go" annotation on
    /// the Beads tab. Nil once someone has passed the last defined tier.
    static func nextTier(after growthValue: Double, tiers: [BeadTier]) -> BeadTier? {
        tiers.first { Double($0.thresholdDays) > growthValue }
    }
}
