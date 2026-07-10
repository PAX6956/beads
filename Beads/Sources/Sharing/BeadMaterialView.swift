import SwiftUI

/// Renders a single bead in a given tier's material. Checks the asset catalog
/// first (`BeadTier1` ... `BeadTier11`, see BeadTier.assetName) and falls back
/// to a procedural gradient placeholder if that tier's real texture hasn't
/// been added yet — so art can land one tier at a time with zero code changes,
/// and every call site (carousel, share card hero) gets the upgrade for free
/// the moment an asset exists.
///
/// Every bead in a strand always renders in the *same*, full-quality style —
/// there used to be a dimmed "not yet reached" variant driven by a per-week
/// progress counter, but on-device comparison across tiers showed it only
/// read clearly on saturated materials (wood, turquoise); on pale ones
/// (pearl, silver, diamond) the desaturation was barely visible, and a strand
/// with some beads dimmed and some not just looked like a mismatched string,
/// not "progress." Progression now lives entirely in which *tier* the whole
/// strand is rendered in, not in per-bead state.
struct BeadMaterialView: View {
    let tier: BeadTier
    let beyondIntensity: Double
    var size: CGFloat = 90

    var body: some View {
        Group {
            if let uiImage = UIImage(named: tier.assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    // .brightness() adds a flat lift to every RGB channel,
                    // which pulls a low-saturation wood tone toward white
                    // rather than just brightening it — the earlier +0.12
                    // lift (added when the images looked too dark) was
                    // overshooting into "washed out." Pulled back down.
                    .brightness(0.03)
                    .contrast(1.05)
            } else {
                placeholder
            }
        }
        .shadow(color: glowColor.opacity(0.45 + beyondIntensity * 0.3), radius: size * (0.3 + sparkle * 0.5))
    }

    private var baseColor: Color { Color(hex: tier.baseColorHex) }
    private var glowColor: Color { Color(hex: tier.glowColorHex) }
    private var sparkle: Double { tier.sparkleIntensity + beyondIntensity * 0.3 }

    private var placeholder: some View {
        Circle()
            .fill(baseColor)
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(tier.glossiness * 0.95), .clear],
                            center: UnitPoint(x: 0.32, y: 0.26),
                            startRadius: 0,
                            endRadius: size * 0.32
                        )
                    )
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(sparkle * 0.6), lineWidth: size * 0.06)
                    .blur(radius: size * 0.08)
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[0], beyondIntensity: 0, size: 90)
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[4], beyondIntensity: 0, size: 90)
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[10], beyondIntensity: 0, size: 90)
    }
    .padding()
    .background(Color.black)
}
