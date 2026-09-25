import Foundation
import SwiftData

@Model
final class PlannedMeal {
    var id: UUID
    var dayKey: String
    var slotRaw: String
    var title: String
    var plannedCalories: Int
    var isLogged: Bool
    var createdAt: Date

    var slot: MealSlot {
        get { MealSlot(rawValue: slotRaw) ?? .snack }
        set { slotRaw = newValue.rawValue }
    }

    init(
        dayKey: String = DayKey.make(),
        slot: MealSlot = .lunch,
        title: String,
        plannedCalories: Int,
        isLogged: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.dayKey = dayKey
        self.slotRaw = slot.rawValue
        self.title = title
        self.plannedCalories = plannedCalories
        self.isLogged = isLogged
        self.createdAt = createdAt
    }
}

enum MealSlot: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var createdAt: Date
    var isUser: Bool
    var text: String

    init(isUser: Bool, text: String, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.isUser = isUser
        self.text = text
    }
}
