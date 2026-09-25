import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device meal estimate from a plate description (Vision labels / user hint).
enum MealWatchService {
    struct Estimate: Equatable {
        var title: String
        var calories: Int
        var proteinG: Double
        var carbsG: Double
        var fatG: Double
        var confidence: Double
        var buddyLine: String
        var usedFoundationModels: Bool
    }

    static func estimate(
        plateDescription: String,
        day: MealWatchBeat.DayContext
    ) async -> Estimate {
        let trimmed = plateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || !day.userHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Estimate(
                title: "Untitled plate",
                calories: 0,
                proteinG: 0,
                carbsG: 0,
                fatG: 0,
                confidence: 0,
                buddyLine: "Need a plate photo or a quick name first.",
                usedFoundationModels: false
            )
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let live = await foundationEstimate(plateDescription: trimmed, day: day) {
                return live
            }
        }
        #endif

        return offlineEstimate(plateDescription: trimmed, day: day)
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func foundationEstimate(
        plateDescription: String,
        day: MealWatchBeat.DayContext
    ) async -> Estimate? {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        default:
            return nil
        }

        let instructions = MealWatchBeat.instructions(day: day)
        let prompt = MealWatchBeat.prompt(plateDescription: plateDescription, day: day)

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            return parseJSON(response.content, usedFM: true)
        } catch {
            return nil
        }
    }
    #endif

    static func parseJSON(_ raw: String, usedFM: Bool) -> Estimate? {
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let title = (obj["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let calories = intValue(obj["calories"])
        guard let title, !title.isEmpty, let calories else { return nil }

        return Estimate(
            title: title,
            calories: max(0, calories),
            proteinG: doubleValue(obj["proteinG"]) ?? 0,
            carbsG: doubleValue(obj["carbsG"]) ?? 0,
            fatG: doubleValue(obj["fatG"]) ?? 0,
            confidence: min(1, max(0, doubleValue(obj["confidence"]) ?? 0.55)),
            buddyLine: MealWatchBeat.sanitizeBuddyLine((obj["buddyLine"] as? String) ?? "Logged. I’m with you."),
            usedFoundationModels: usedFM
        )
    }

    static func offlineEstimate(
        plateDescription: String,
        day: MealWatchBeat.DayContext
    ) -> Estimate {
        let hint = day.userHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = hint.isEmpty ? plateDescription : hint
        let lower = source.lowercased()

        var calories = 420
        var title = "Plate"
        var protein = 18.0
        var carbs = 40.0
        var fat = 16.0

        if lower.contains("salad") {
            title = "Salad bowl"; calories = 280; protein = 12; carbs = 24; fat = 14
        } else if lower.contains("rice") || lower.contains("bowl") {
            title = "Rice bowl"; calories = 520; protein = 22; carbs = 68; fat = 14
        } else if lower.contains("pizza") {
            title = "Pizza"; calories = 640; protein = 24; carbs = 72; fat = 26
        } else if lower.contains("coffee") || lower.contains("latte") {
            title = "Coffee drink"; calories = 180; protein = 8; carbs = 18; fat = 7
        } else if lower.contains("egg") {
            title = "Eggs"; calories = 320; protein = 22; carbs = 4; fat = 22
        } else if !hint.isEmpty {
            title = String(hint.prefix(28))
        } else if !plateDescription.isEmpty {
            title = String(plateDescription.split(separator: ",").first.map(String.init)?.prefix(28) ?? "Plate")
        }

        let line: String
        if day.caloriesSoFar + calories > day.target {
            line = "That’s on the board. We’re past the target — still worth logging."
        } else {
            line = "Got it. \(calories) kcal on this plate — logged with you."
        }

        return Estimate(
            title: title,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            confidence: hint.isEmpty ? 0.35 : 0.5,
            buddyLine: line,
            usedFoundationModels: false
        )
    }

    private static func intValue(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        if let s = any as? String { return Int(s) }
        if let d = any as? Double { return Int(d.rounded()) }
        return nil
    }

    private static func doubleValue(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s) }
        if let i = any as? Int { return Double(i) }
        return nil
    }
}
