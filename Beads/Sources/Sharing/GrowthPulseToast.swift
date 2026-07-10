import SwiftUI

/// A brief toast shown after practice/journal/share — the point isn't the
/// toast itself, it's giving each of those three actions a visible, immediate
/// answer to "did that matter?" that points at the one thing all three feed:
/// the bracelet. `leveledUp` swaps in a bigger moment for the rare case an
/// action actually crossed into a new material tier, not just nudged the
/// counter.
struct GrowthPulseToast: View {
    let tier: BeadTier
    let beyondIntensity: Double
    let leveledUp: Bool

    var body: some View {
        HStack(spacing: 10) {
            BeadMaterialView(tier: tier, beyondIntensity: beyondIntensity, size: 30)
            Text(leveledUp ? "Your string reached a new tier — \(tier.localizedName)." : "Your string just changed a little.")
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .shadow(radius: 6, y: 2)
    }
}

private struct GrowthPulseModifier: ViewModifier {
    @Binding var isPresented: Bool
    let tier: BeadTier?
    let beyondIntensity: Double
    let leveledUp: Bool

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented, let tier {
                GrowthPulseToast(tier: tier, beyondIntensity: beyondIntensity, leveledUp: leveledUp)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeOut(duration: 0.3)) { isPresented = false }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPresented)
    }
}

extension View {
    func growthPulse(isPresented: Binding<Bool>, tier: BeadTier?, beyondIntensity: Double, leveledUp: Bool) -> some View {
        modifier(GrowthPulseModifier(isPresented: isPresented, tier: tier, beyondIntensity: beyondIntensity, leveledUp: leveledUp))
    }
}
