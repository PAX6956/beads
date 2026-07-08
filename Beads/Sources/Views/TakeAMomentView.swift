import SwiftUI

/// The calm, non-punitive version of the "panic button" idea from the Quittr
/// analysis: no shame, no camera, no urge to resist — just a short breathing
/// cycle and a quote at the end. Available any time, not just during a streak.
/// Deliberately atmospheric (dark, glowing, slow) rather than clinical —
/// the ritual feeling is doing real work here, not just decoration.
struct TakeAMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()
    @State private var displayedLabel = "Breathe in…"
    @State private var labelOpacity: Double = 1

    private static let phaseDuration: Double = 4
    private static let cycleDuration = phaseDuration * 4
    private static let totalDuration = cycleDuration * 4
    private static let fadeDuration: Double = 0.35

    private let calmQuote: String = {
        let library = ContentLibrary.loadSeed()
        let calmItems = library.filter { $0.tags.contains("calm") }
        return (calmItems.randomElement() ?? library.randomElement())?.localizedQuote ?? "Take a quiet breath."
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let isFinished = elapsed >= Self.totalDuration
            let phase = breathPhase(at: elapsed.truncatingRemainder(dividingBy: Self.cycleDuration))

            ZStack {
                backgroundGradient
                starField(elapsed: elapsed)

                VStack(spacing: 48) {
                    Spacer()
                    if isFinished {
                        Text(calmQuote)
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    } else {
                        breathingOrb(scale: phase.scale, elapsed: elapsed)
                        Text(LocalizedStringKey(displayedLabel))
                            .font(.system(.title2, design: .serif).weight(.light))
                            .foregroundStyle(.white.opacity(0.85))
                            .tracking(3)
                            .opacity(labelOpacity)
                            .onChange(of: phase.label) { newValue in
                                fadeToLabel(newValue)
                            }
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(.bordered)
                        .tint(.white)
                }
                .padding()
                .animation(.easeInOut(duration: 1.2), value: isFinished)
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Fades the label fully out, swaps the text while invisible, then fades
    /// it back in — a clean cut rather than a crossfade, so old and new text
    /// are never partially overlapping (that was reading as a ghosting artifact).
    private func fadeToLabel(_ newValue: String) {
        withAnimation(.easeInOut(duration: Self.fadeDuration)) {
            labelOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.fadeDuration) {
            displayedLabel = newValue
            withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                labelOpacity = 1
            }
        }
    }

    private var backgroundGradient: some View {
        RadialGradient(
            colors: [Color.accentColor.opacity(0.45), Color.accentColor.opacity(0.12), .black],
            center: .center,
            startRadius: 10,
            endRadius: 420
        )
        .ignoresSafeArea()
    }

    /// A hollow ring rather than a filled orb. Three angular gradients spin at
    /// different speeds and directions (rather than one), plus a few small
    /// bright points sliding independently around the circumference, so the
    /// highlights drift and cross unpredictably instead of rotating as one
    /// rigid pattern — closer to how light actually moves across a liquid
    /// surface. A real fluid/refractive look would need a custom Metal shader
    /// (iOS 17+ layerEffect); this is the SwiftUI-only approximation of that,
    /// to push further together later if it's still not enough.
    ///
    /// Safety note: an earlier version used several independently-rotating
    /// high-contrast gradients plus small fast-moving points, and the
    /// overlapping bright/dark bands crossing each other read as flicker —
    /// a real photosensitivity risk, not just a look we didn't like. This
    /// version is deliberately conservative: exactly one gradient, no hard
    /// transparent/opaque jumps (only gradual stops), slow rotation (a full
    /// turn takes ~45 seconds), and the ring itself is softly blurred so
    /// there's no hard edge anywhere to strobe in the first place.
    private func breathingOrb(scale: CGFloat, elapsed: Double) -> some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.22))
                .frame(width: 220, height: 220)
                .scaleEffect(scale)
                .blur(radius: 30)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            .init(color: Color.accentColor.opacity(0.55), location: 0.0),
                            .init(color: .white.opacity(0.85), location: 0.25),
                            .init(color: Color.accentColor.opacity(0.55), location: 0.5),
                            .init(color: .white.opacity(0.6), location: 0.75),
                            .init(color: Color.accentColor.opacity(0.55), location: 1.0)
                        ],
                        center: .center,
                        angle: .degrees(elapsed * 8)
                    ),
                    lineWidth: 14
                )
                .frame(width: 140, height: 140)
                .scaleEffect(scale)
                .blur(radius: 3)
                .shadow(color: Color.accentColor.opacity(0.6), radius: 28)
        }
        .animation(.easeInOut(duration: Self.phaseDuration), value: scale)
    }

    /// Slow-drifting points of light around the orb — pure atmosphere, tied to
    /// the same TimelineView clock so no separate animation state is needed.
    private func starField(elapsed: Double) -> some View {
        ZStack {
            ForEach(0..<18, id: \.self) { index in
                let angle = Double(index) / 18 * 2 * .pi + elapsed * 0.04
                let radius = 130.0 + Double(index % 4) * 34
                let twinkle = 0.2 + 0.2 * sin(elapsed * 0.6 + Double(index))
                Circle()
                    .fill(Color.white.opacity(twinkle))
                    .frame(width: 3, height: 3)
                    .offset(x: cos(angle) * radius, y: sin(angle) * radius * 0.75)
            }
        }
    }

    private func breathPhase(at position: Double) -> (label: String, scale: CGFloat) {
        switch position {
        case 0..<Self.phaseDuration: return ("Breathe in…", 1.55)
        case Self.phaseDuration..<(Self.phaseDuration * 2): return ("Hold…", 1.55)
        case (Self.phaseDuration * 2)..<(Self.phaseDuration * 3): return ("Breathe out…", 0.65)
        default: return ("Hold…", 0.65)
        }
    }
}

#Preview {
    TakeAMomentView()
}
