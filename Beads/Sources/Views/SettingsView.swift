import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var exportURL: URL?
    @State private var isShowingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var didDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Export my data", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportURL = store.exportDataFile()
                        } label: {
                            Label("Export my data", systemImage: "square.and.arrow.up")
                        }
                    }

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            Label("Deleting…", systemImage: "trash")
                        } else {
                            Label("Delete all my data", systemImage: "trash")
                        }
                    }
                    .disabled(isDeleting)
                } footer: {
                    Text("Beads stores your practice and journal entries only in your own iCloud account — nothing is shared with anyone unless you choose to share a Ripple Card.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete all your data? This can't be undone.",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    isDeleting = true
                    Task {
                        await store.deleteAllData()
                        exportURL = nil
                        isDeleting = false
                        didDelete = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("All your data has been deleted.", isPresented: $didDelete) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PracticeStore())
}
