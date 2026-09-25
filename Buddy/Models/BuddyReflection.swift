import Foundation

/// Local reflection of the user's recent eating onto Buddy's body.
/// Playful mirror — not body-shaming. Calories-first (RP), protein nudges muscle.
struct BuddyReflection: Equatable {
    /// 0 = full / fed, 1 = very hungry
    var hunger: Double
    /// 0 = lean ghost, 1 = round / soft
    var softness: Double
    /// 0 = soft, 1 = built (protein-forward)
    var muscle: Double

    var form: BuddyForm {
        if hunger >= 0.55 { return .hungry }
        if muscle >= 0.55 && softness < 0.45 { return .strong }
        if softness >= 0.55 { return .soft }
        return .balanced
    }

    /// Melting / droopy eyes — beyond “a bit hungry.”
    var isSuperHungry: Bool { hunger >= 0.72 }

    var label: String { form.label }

    var blurb: String {
        if isSuperHungry { return "Wilted. Feed me a plate?" }
        return form.blurb
    }

    static let neutral = BuddyReflection(hunger: 0.15, softness: 0.2, muscle: 0.25)

    /// Build from recent plates + daily target. Pure local math.
    static func compute(
        plates: [PlateSnapshot],
        dailyTarget: Int,
        now: Date = .now
    ) -> BuddyReflection {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -2, to: cal.startOfDay(for: now)) ?? now
        let recent = plates.filter { $0.createdAt >= start }
        let days = 3.0
        let target = Double(max(dailyTarget, 1200))
        let kcal = Double(recent.reduce(0) { $0 + $1.calories })
        let protein = recent.reduce(0.0) { $0 + $1.proteinG }
        let fat = recent.reduce(0.0) { $0 + $1.fatG }

        let energyRatio = kcal / (target * days) // 1.0 = on plan across window
        let todayKey = DayKey.make(now)
        let todayKcal = recent.filter { DayKey.make($0.createdAt) == todayKey }
            .reduce(0) { $0 + $1.calories }
        let hour = cal.component(.hour, from: now)

        // Hunger: under-eating window, or empty afternoon/evening today
        var hunger = max(0, min(1, 1.15 - energyRatio))
        if todayKcal == 0 && hour >= 14 {
            hunger = max(hunger, 0.65)
        } else if todayKcal == 0 && hour >= 11 {
            hunger = max(hunger, 0.4)
        } else if Double(todayKcal) < target * 0.35 && hour >= 18 {
            hunger = max(hunger, 0.5)
        }

        // Softness: surplus + dietary fat share
        let surplus = max(0, energyRatio - 1.0)
        let fatShare = kcal > 0 ? (fat * 9) / kcal : 0
        var softness = max(0, min(1, surplus * 2.2 + max(0, fatShare - 0.3)))
        if energyRatio < 0.9 { softness *= 0.35 }

        // Muscle: protein density near maintenance (not a crash cut)
        let proteinPerDay = protein / days
        // ~0.8–1.0 g/lb ≈ rough; without BW use protein kcal share + absolute floor
        let proteinShare = kcal > 0 ? (protein * 4) / kcal : 0
        var muscle = 0.0
        if energyRatio >= 0.85 && energyRatio <= 1.15 {
            muscle = max(0, min(1, (proteinShare - 0.18) / 0.2))
        } else if energyRatio > 1.15 && proteinShare >= 0.22 {
            muscle = max(0, min(1, (proteinShare - 0.2) / 0.25)) * 0.7
        }
        if proteinPerDay >= 120 { muscle = max(muscle, 0.55) }
        if proteinPerDay >= 160 { muscle = max(muscle, 0.75) }

        // Don't look jacked while starving
        if hunger > 0.6 { muscle *= 0.4 }

        return BuddyReflection(
            hunger: hunger.clamped01,
            softness: softness.clamped01,
            muscle: muscle.clamped01
        )
    }
}

struct PlateSnapshot: Equatable {
    var createdAt: Date
    var calories: Int
    var proteinG: Double
    var fatG: Double

    init(from plate: PlateEntry) {
        createdAt = plate.createdAt
        calories = plate.calories
        proteinG = plate.proteinG
        fatG = plate.fatG
    }

    init(createdAt: Date, calories: Int, proteinG: Double, fatG: Double) {
        self.createdAt = createdAt
        self.calories = calories
        self.proteinG = proteinG
        self.fatG = fatG
    }
}

enum BuddyForm: String, CaseIterable {
    case hungry
    case soft
    case strong
    case balanced

    var label: String {
        switch self {
        case .hungry: return "Hungry"
        case .soft: return "Soft"
        case .strong: return "Strong"
        case .balanced: return "Steady"
        }
    }

    var blurb: String {
        switch self {
        case .hungry: return "Running light — feed me a plate?"
        case .soft: return "Padded out from the surplus. Still cute."
        case .strong: return "Protein’s been showing up. Feeling solid."
        case .balanced: return "Mirroring your day. What’s up, bud?"
        }
    }
}

private extension Double {
    var clamped01: Double { min(1, max(0, self)) }
}
