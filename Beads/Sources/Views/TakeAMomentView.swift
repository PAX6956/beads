import SwiftUI

/// The calm, non-punitive version of the "panic button" idea from the Quittr
/// analysis: no shame, no camera, no urge to resist — just a short breathing
/// cycle and a quote at the end. Available any time, not just during a streak.
struct TakeAMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()

    private static let phaseDuration: Double = 4
    private static let cycleDuration = phaseDuration * 4
    private static let totalDuration = cycleDuration * 4

    private let calmQuote: String = {
        let library = ContentLibrary.loadSeed()
        let calmItems = library.filter { $0.tags.contains("calm") }
        return (calmItems.randomElement() ?? library.randomElement())?.quote ?? "Take a quiet breath."
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(startDate)
            let isFinished = elapsed >= Self.totalDuration
            let phase = breathPhase(at: elapsed.truncatingRemainder(dividingBy: Self.cycleDuration))

            VStack(spacing: 32) {
                Spacer()
                if isFinished {
                    Text(calmQuote)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                } else {
                    Circle()
                        .fill(Color.accentColor.opacity(0.25))
                        .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2))
                        .frame(width: 160, height: 160)
                        .scaleEffect(phase.scale)
                        .animation(.easeInOut(duration: Self.phaseDuration), value: phase.label)
                    Text(phase.label)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }

    private func breathPhase(at position: Double) -> (label: String, scale: CGFloat) {
        switch position {
        case 0..<Self.phaseDuration: return ("Breathe in…", 1.3)
        case Self.phaseDuration..<(Self.phaseDuration * 2): return ("Hold…", 1.3)
        case (Self.phaseDuration * 2)..<(Self.phaseDuration * 3): return ("Breathe out…", 0.85)
        default: return ("Hold…", 0.85)
        }
    }
}

#Preview {
    TakeAMomentView()
}
