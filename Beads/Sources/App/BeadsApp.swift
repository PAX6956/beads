import SwiftUI

@main
struct BeadsApp: App {
    @StateObject private var store = PracticeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
