import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            BeadsProgressView()
                .tabItem { Label("Beads", systemImage: "circle.grid.cross") }

            JournalView()
                .tabItem { Label("Journal", systemImage: "book") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(PracticeStore())
}
