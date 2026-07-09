import SwiftUI

/// Shown once, on the very first launch — before this, a new user landed cold
/// on Today with no explanation of what the bead/streak/patina system even
/// is. Deliberately a single screen, not a multi-page tour, matching the
/// same "one line of guidance is enough" scope as TakeAMomentView's intro.
struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var firstTier: BeadTier? {
        BeadTierLibrary.loadTiers().first
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            if let firstTier {
                BeadMaterialView(tier: firstTier, beyondIntensity: 0, reached: true, size: 96)
            }

            VStack(spacing: 12) {
                Text("Welcome to Beads")
                    .font(.system(.title2, design: .serif).weight(.medium))
                Text("Each day you show up, this string quietly changes — texture, color, the way it catches light. Not a grade, just a record of being here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 8) {
                Button {
                    Haptics.lightTap()
                    hasCompletedOnboarding = true
                    Task {
                        await NotificationScheduler.requestAuthorizationIfNeeded()
                        NotificationScheduler.rescheduleUpcoming()
                    }
                    dismiss()
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)

                Text("We'll also ask if you'd like a daily reminder — you can always change this later in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled()
    }
}

#Preview {
    WelcomeView()
}
