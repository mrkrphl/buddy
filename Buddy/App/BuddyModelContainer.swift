import Foundation
import SwiftData

enum BuddyModelContainer {
    static let shared: ModelContainer = {
        do {
            return try make()
        } catch {
            fatalError("Buddy store failed: \(error)")
        }
    }()

    static func make() throws -> ModelContainer {
        let schema = Schema([
            PlateEntry.self,
            BuddyProgress.self,
            BuddyPreferences.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
