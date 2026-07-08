#if DEBUG
import SwiftUI

/// Lets you see every tier's actual on-device rendering without waiting years
/// to earn them — the offscreen macOS render used during development is a
/// useful first pass, but the real screen (OLED color, glow blending) is the
/// real check. Uses the real interactive 3D carousel (not the flat ring) so
/// new texture art can actually be inspected the way a user would see it —
/// drag to spin, check it from every angle. DEBUG-only, reachable from Settings.
struct BeadTierDebugView: View {
    private let tiers = BeadTierLibrary.loadTiers()
    @State private var selectedTier: BeadTier?

    var body: some View {
        VStack(spacing: 16) {
            if let selectedTier {
                // Full cycleProgress means every visible bead is "reached" —
                // shown at full saturation, not the dimmed unreached look —
                // since the point here is judging the material itself.
                BeadCarouselView(tier: selectedTier, beyondIntensity: 0, cycleProgress: BeadRingView.ringCapacity)
                    .id(selectedTier.id)

                VStack(spacing: 2) {
                    Text("\(selectedTier.order). \(selectedTier.name) · \(selectedTier.nameZh ?? "—")")
                        .font(.headline)
                    Text("from day \(selectedTier.thresholdDays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            tierPicker

            Spacer(minLength: 0)
        }
        .padding(.top, 16)
        .navigationTitle("Tier Preview")
        .onAppear {
            if selectedTier == nil { selectedTier = tiers.first }
        }
    }

    private var tierPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tiers) { tier in
                    Button {
                        selectedTier = tier
                    } label: {
                        VStack(spacing: 4) {
                            BeadMaterialView(tier: tier, beyondIntensity: 0, reached: true, size: 44)
                            Text("\(tier.order)")
                                .font(.caption2.weight(.semibold))
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTier?.id == tier.id ? Color.accentColor.opacity(0.2) : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        BeadTierDebugView()
            .environmentObject(PracticeStore())
    }
}
#endif
