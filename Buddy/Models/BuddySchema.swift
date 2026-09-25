import Foundation
import SwiftData

@Model
final class PlateEntry {
    var id: UUID
    var createdAt: Date
    var title: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var confidence: Double
    var buddyLine: String
    var notes: String
    /// JPEG data of the plate photo (on-device only).
    @Attribute(.externalStorage) var photoData: Data?

    init(
        title: String,
        calories: Int,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0,
        confidence: Double = 0.5,
        buddyLine: String = "",
        notes: String = "",
        photoData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.title = title
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.confidence = confidence
        self.buddyLine = buddyLine
        self.notes = notes
        self.photoData = photoData
    }
}

@Model
final class BuddyProgress {
    var id: UUID
    var xp: Int
    var level: Int
    var streakDays: Int
    var lastWatchDayKey: String
    var moodRaw: String

    var mood: BuddyMood {
        get { BuddyMood(rawValue: moodRaw) ?? .curious }
        set { moodRaw = newValue.rawValue }
    }

    init(
        xp: Int = 0,
        level: Int = 1,
        streakDays: Int = 0,
        lastWatchDayKey: String = "",
        mood: BuddyMood = .curious
    ) {
        self.id = UUID()
        self.xp = xp
        self.level = level
        self.streakDays = streakDays
        self.lastWatchDayKey = lastWatchDayKey
        self.moodRaw = mood.rawValue
    }

    static func xpToAdvance(from level: Int) -> Int {
        40 + (level * 20)
    }

    func awardWatch(on dayKey: String, xpGain: Int = 15) {
        if lastWatchDayKey != dayKey {
            if let last = Self.date(from: lastWatchDayKey),
               let today = Self.date(from: dayKey),
               Calendar.current.dateComponents([.day], from: last, to: today).day == 1 {
                streakDays += 1
            } else if lastWatchDayKey.isEmpty {
                streakDays = 1
            } else {
                streakDays = 1
            }
            lastWatchDayKey = dayKey
        }
        xp += xpGain
        while xp >= Self.xpToAdvance(from: level) {
            xp -= Self.xpToAdvance(from: level)
            level += 1
        }
        mood = streakDays >= 3 ? .proud : .curious
    }

    private static func date(from dayKey: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: dayKey)
    }
}

@Model
final class BuddyPreferences {
    var id: UUID
    var dailyCalorieTarget: Int
    var hasSeenOnboarding: Bool
    /// Raw values of `KitchenApplianceID` the user owns.
    var ownedApplianceIDs: [String] = []
    /// Optional per-appliance notes, keyed by appliance raw value.
    var applianceNotesJSON: String = "{}"

    var ownedAppliances: Set<KitchenApplianceID> {
        get { KitchenApplianceStore.decodeIDs(ownedApplianceIDs) }
        set { ownedApplianceIDs = KitchenApplianceStore.encodeIDs(newValue) }
    }

    var applianceNotes: [String: String] {
        get {
            guard let data = applianceNotesJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let s = String(data: data, encoding: .utf8) {
                applianceNotesJSON = s
            } else {
                applianceNotesJSON = "{}"
            }
        }
    }

    init(
        dailyCalorieTarget: Int = 2200,
        hasSeenOnboarding: Bool = false,
        ownedApplianceIDs: [String] = [],
        applianceNotesJSON: String = "{}"
    ) {
        self.id = UUID()
        self.dailyCalorieTarget = dailyCalorieTarget
        self.hasSeenOnboarding = hasSeenOnboarding
        self.ownedApplianceIDs = ownedApplianceIDs
        self.applianceNotesJSON = applianceNotesJSON
    }

    func note(for id: KitchenApplianceID) -> String {
        applianceNotes[id.rawValue] ?? ""
    }

    func setNote(_ note: String, for id: KitchenApplianceID) {
        var map = applianceNotes
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            map.removeValue(forKey: id.rawValue)
        } else {
            map[id.rawValue] = trimmed
        }
        applianceNotes = map
    }
}

enum BuddyMood: String, CaseIterable, Codable {
    case curious
    case proud
    case sleepy
    case hyped

    var label: String {
        switch self {
        case .curious: return "Curious"
        case .proud: return "Proud"
        case .sleepy: return "Sleepy"
        case .hyped: return "Hyped"
        }
    }

    var systemImage: String {
        switch self {
        case .curious: return "eye"
        case .proud: return "sparkles"
        case .sleepy: return "moon.zzz"
        case .hyped: return "bolt.fill"
        }
    }
}

enum DayKey {
    static func make(_ date: Date = .now) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
