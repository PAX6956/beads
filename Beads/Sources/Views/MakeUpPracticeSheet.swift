import SwiftUI

/// PRD requires a brief reflection to make up a missed day, rather than a bare
/// one-tap — keeps the streak mechanic from becoming trivially gameable.
struct MakeUpPracticeSheet: View {
    let date: Date

    @EnvironmentObject private var store: PracticeStore
    @Environment(\.dismiss) private var dismiss
    @State private var reflection = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's one thing that felt calm, even briefly, on \(date.formatted(date: .abbreviated, time: .omitted))?")
                    .font(.body)
                TextField("A short reflection", text: $reflection, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Spacer()
            }
            .padding()
            .navigationTitle("Make Up Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete") {
                        store.makeUp(date: date)
                        store.addJournalEntry(text: reflection, moods: [])
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    MakeUpPracticeSheet(date: Date())
        .environmentObject(PracticeStore())
}
