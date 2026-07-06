import SwiftUI

@main
struct BeadsApp: App {
    @StateObject private var store = PracticeStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        store.refreshFromDisk()
                        Task {
                            await NotificationScheduler.requestAuthorizationIfNeeded()
                            NotificationScheduler.rescheduleUpcoming()
                        }
                    }
                }
        }
    }
}
