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
                    BeadMaterialView(
                        tier: tierInfo.tier,
                        beyondIntensity: tierInfo.beyondIntensity,
                        reached: index < cycleProgress,
                        size: size * 0.16
                    )
                    .rotationEffect(BeadStrandJitter.rotation(for: index))
                    .offset(x: cos(angle) * size / 2, y: sin(angle) * size / 2)
                }
            }
        }
        .frame(width: size, height: size)
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
