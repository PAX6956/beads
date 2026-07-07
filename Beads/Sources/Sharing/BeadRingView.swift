import SwiftUI

/// The small "show off your patina" ring — quantity (how far into the current
/// 12-week bracelet you are) and patina tier (lifetime cumulative practice,
/// never resets) are deliberately separate dimensions. All 12 positions are
/// always visible from day one (pale/unreached), matching how a real bracelet
/// is a complete object from the start that only changes in appearance, not
/// in bead count — and giving even a brand-new user a visible, bounded goal
/// rather than nothing to look at.
struct BeadRingView: View {
    let lifetimeDays: Int
    let cycleProgress: Int
    var size: CGFloat = 120

    static let ringCapacity = 12

    private var tierInfo: (tier: BeadTier, beyondIntensity: Double)? {
        BeadTierLibrary.currentTier(lifetimeDays: lifetimeDays, tiers: BeadTierLibrary.loadTiers())
    }

    var body: some View {
        ZStack {
            if let tierInfo {
                ForEach(0..<Self.ringCapacity, id: \.self) { index in
                    let angle = Double(index) / Double(Self.ringCapacity) * 2 * .pi - .pi / 2
                    let reached = index < cycleProgress
                    beadDot(tier: tierInfo.tier, beyondIntensity: tierInfo.beyondIntensity, reached: reached)
                        .offset(x: cos(angle) * size / 2, y: sin(angle) * size / 2)
                }
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func beadDot(tier: BeadTier, beyondIntensity: Double, reached: Bool) -> some View {
        let baseColor = Color(hex: tier.baseColorHex)
        let glowColor = Color(hex: tier.glowColorHex)
        let dotSize = size * 0.16
        let sparkle = reached ? tier.sparkleIntensity + beyondIntensity * 0.3 : 0

        Circle()
            .fill(reached ? baseColor : baseColor.opacity(0.22))
            .frame(width: dotSize, height: dotSize)
            .overlay(
                // A tight specular highlight rather than a broad wash — real
                // shine is a small bright spot, not the whole surface fading
                // toward white. Keeps dark/rich colors (e.g. Patina) reading
                // as dark even at high glossiness, instead of washing pale.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(reached ? tier.glossiness * 0.95 : 0), .clear],
                            center: UnitPoint(x: 0.32, y: 0.26),
                            startRadius: 0,
                            endRadius: dotSize * 0.32
                        )
                    )
            )
            .overlay(
                Circle()
                    .strokeBorder(.white.opacity(sparkle * 0.6), lineWidth: dotSize * 0.06)
                    .blur(radius: dotSize * 0.08)
            )
            .shadow(color: reached ? glowColor.opacity(0.45 + beyondIntensity * 0.3) : .clear,
                    radius: reached ? dotSize * (0.3 + sparkle * 0.5) : 0)
    }
}

#Preview {
    VStack(spacing: 24) {
        BeadRingView(lifetimeDays: 2, cycleProgress: 0)
        BeadRingView(lifetimeDays: 45, cycleProgress: 4)
        BeadRingView(lifetimeDays: 400, cycleProgress: 8)
        BeadRingView(lifetimeDays: 1000, cycleProgress: 12)
    }
    .padding()
}
