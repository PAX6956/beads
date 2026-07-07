import SwiftUI

/// Renders a single bead in a given tier's material. Checks the asset catalog
/// first (`BeadTier1` ... `BeadTier11`, see BeadTier.assetName) and falls back
/// to a procedural gradient placeholder if that tier's real texture hasn't
/// been added yet — so art can land one tier at a time with zero code changes,
/// and every call site (carousel, share card hero) gets the upgrade for free
/// the moment an asset exists.
struct BeadMaterialView: View {
    let tier: BeadTier
    let beyondIntensity: Double
    let reached: Bool
    var size: CGFloat = 90

    var body: some View {
        Group {
            if let uiImage = UIImage(named: tier.assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .opacity(reached ? 1 : 0.35)
            } else {
                placeholder
            }
        }
        .shadow(color: reached ? glowColor.opacity(0.45 + beyondIntensity * 0.3) : .clear,
                radius: reached ? size * (0.3 + sparkle * 0.5) : 0)
    }

    private var baseColor: Color { Color(hex: tier.baseColorHex) }
    private var glowColor: Color { Color(hex: tier.glowColorHex) }
    private var sparkle: Double { reached ? tier.sparkleIntensity + beyondIntensity * 0.3 : 0 }

    private var placeholder: some View {
        Circle()
            .fill(reached ? baseColor : baseColor.opacity(0.22))
            .overlay(
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(reached ? tier.glossiness * 0.95 : 0), .clear],
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
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[0], beyondIntensity: 0, reached: true, size: 90)
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[4], beyondIntensity: 0, reached: true, size: 90)
        BeadMaterialView(tier: BeadTierLibrary.loadTiers()[10], beyondIntensity: 0, reached: true, size: 90)
    }
    .padding()
    .background(Color.black)
}
