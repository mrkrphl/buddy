import Foundation

/// Prompt pack for plate → meal estimate (Foundation Models).
enum MealWatchBeat {
    struct DayContext {
        var caloriesSoFar: Int
        var target: Int
        var plateCount: Int
        var userHint: String
    }

    static func instructions(day: DayContext) -> String {
        """
        \(BuddyPeerBase.identity)
        \(BuddyPeerBase.dayLine(caloriesSoFar: day.caloriesSoFar, target: day.target, plateCount: day.plateCount))

        Task: from a plate description (and optional user hint), estimate the meal.
        Return ONLY a single JSON object with keys:
        title (string, short food name),
        calories (int, kcal for the portion shown),
        proteinG (number),
        carbsG (number),
        fatG (number),
        confidence (number 0–1),
        buddyLine (string, 1 short reaction, no guilt).
        No markdown fences. No extra keys. No commentary outside JSON.
        """
    }

    static func prompt(plateDescription: String, day: DayContext) -> String {
        let hint = day.userHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let hintBlock = hint.isEmpty ? "(none)" : hint
        return """
        Plate description (from on-device vision / user):
        \"\"\"
        \(plateDescription.prefix(3500))
        \"\"\"

        User hint:
        \(hintBlock)

        Estimate the meal as JSON.
        """
    }

    static func sanitizeBuddyLine(_ raw: String) -> String {
        var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let banned = ["Certainly", "Of course", "Absolutely", "Sure,", "Great question", "As an AI"]
        for b in banned where t.hasPrefix(b) {
            if let r = t.range(of: ".") {
                t = String(t[r.upperBound...]).trimmingCharacters(in: .whitespaces)
            }
        }
        if t.count > 160 { t = String(t.prefix(157)) + "…" }
        return t
    }
}
