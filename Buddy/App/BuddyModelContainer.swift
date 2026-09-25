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
            BuddyPreferences.self,
            PlannedMeal.self,
            ChatMessage.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            Self.destroyStore(at: config.url)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    private static func destroyStore(at url: URL) {
        let fm = FileManager.default
        let candidates = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal"),
            url.deletingLastPathComponent()
        ]
        // Prefer deleting the whole Application Support folder for this app store.
        if let support = candidates.last {
            try? fm.removeItem(at: support)
            try? fm.createDirectory(at: support, withIntermediateDirectories: true)
        }
        for u in candidates.dropLast() {
            try? fm.removeItem(at: u)
        }
    }
}
