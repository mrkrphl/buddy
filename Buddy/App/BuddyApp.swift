import SwiftData
import SwiftUI

@main
struct BuddyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(BuddyModelContainer.shared)
        }
    }
}
