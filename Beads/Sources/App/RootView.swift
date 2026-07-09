import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
        .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { hasCompletedOnboarding = !$0 })) {
            WelcomeView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(PracticeStore())
}
