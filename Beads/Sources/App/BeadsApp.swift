import SwiftUI

@main
struct BeadsApp: App {
    @StateObject private var store = PracticeStore()
    @StateObject private var purchases = PurchaseManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(purchases)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        store.refreshFromDisk()
                        // Permission itself is only ever requested from
                        // WelcomeView's "Get Started" tap, with context —
                        // asking blind on first launch (before the user has
                        // seen a single screen of the app) reads as a cold
                        // system dialog with no explanation. Rescheduling
                        // here is safe either way: it silently no-ops for
                        // anyone who hasn't granted permission yet.
                        NotificationScheduler.rescheduleUpcoming()
                    }
                }
        }
    }
}
