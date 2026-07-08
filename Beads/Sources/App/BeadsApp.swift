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
                        Task {
                            await NotificationScheduler.requestAuthorizationIfNeeded()
                            NotificationScheduler.rescheduleUpcoming()
                        }
                    }
                }
        }
    }
}
