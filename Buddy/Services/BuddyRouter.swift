import SwiftUI

/// Cross-tab signal from a chat confirm. Parents that own the tab bar
/// publish an instance. Chat still works when none is published.
@MainActor
final class BuddyRouter: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var logPlatePulseToken: Int = 0

    func openTodayForLogging() {
        selectedTab = 0
        logPlatePulseToken &+= 1
    }
}

private struct BuddyRouterKey: EnvironmentKey {
    static let defaultValue: BuddyRouter? = nil
}

extension EnvironmentValues {
    var buddyRouter: BuddyRouter? {
        get { self[BuddyRouterKey.self] }
        set { self[BuddyRouterKey.self] = newValue }
    }
}
