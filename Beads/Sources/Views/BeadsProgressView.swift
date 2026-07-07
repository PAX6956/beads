import SwiftUI

struct BeadsProgressView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    BeadRingView(
                        lifetimeDays: store.practiceEntries.count,
                        cycleProgress: store.beadCount % BeadRingView.ringCapacity,
                        size: 100
                    )
                    .padding(.top, 8)

                    Text("\(store.currentStreak) day streak")
                        .font(.largeTitle.weight(.bold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(0..<max(store.beadCount + 1, 1), id: \.self) { index in
                                bead(filled: index < store.beadCount,
                                     isCurrent: index == store.beadCount)
                            }
                        }
                        .padding()
                    }

                    ProgressView(value: store.progressToNextBead)
                        .padding(.horizontal)

                    Text("\(7 - Int(store.progressToNextBead * 7)) days to your next bead")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Divider()

                    HistoryCalendarView()
                }
                .padding(.top, 32)
            }
            .navigationTitle("Beads")
        }
    }

    private func bead(filled: Bool, isCurrent: Bool) -> some View {
        Circle()
            .fill(filled ? Color.accentColor : Color.gray.opacity(0.25))
            .frame(width: 44, height: 44)
            .overlay(
                Circle().strokeBorder(isCurrent ? Color.accentColor : .clear, lineWidth: 3)
            )
    }
}

#Preview {
    BeadsProgressView()
        .environmentObject(PracticeStore())
}
