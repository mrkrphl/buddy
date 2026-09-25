import Foundation

/// Chat / check-in prompt pack — RP-grounded food & fitness companion (local FM).
enum BuddyTalkBeat {
    struct Context {
        var caloriesToday: Int
        var target: Int
        var plateCount: Int
        var reflection: BuddyReflection
        var plannedTitles: [String]
    }

    static func instructions(ctx: Context) -> String {
        """
        \(BuddyPeerBase.identity)

        You are also Buddy’s chat voice — food & fitness companion, on-device only.
        Expert framing (Renaissance-style priorities, plain language):
        1) Calorie balance matters most for body change.
        2) Protein next; carbs/fats support training and adherence.
        3) Timing and “clean” foods matter far less than consistency.
        4) Adherence beats a perfect plan. Never shame food.

        Current local context:
        \(BuddyPeerBase.dayLine(caloriesSoFar: ctx.caloriesToday, target: ctx.target, plateCount: ctx.plateCount))
        Buddy body mirror: \(ctx.reflection.label) — \(ctx.reflection.blurb)
        Planned (not necessarily logged): \(ctx.plannedTitles.isEmpty ? "(none)" : ctx.plannedTitles.joined(separator: ", "))

        Reply in 1–3 short sentences. No markdown. No bullet lists unless asked.
        Never diagnose disease. Never prescribe extreme deficits. If asked medical questions, say see a clinician.
        """
    }

    static func userPrompt(_ message: String) -> String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func openingLine(reflection: BuddyReflection) -> String {
        switch reflection.form {
        case .hungry:
            return "What’s up, bud? I’m running light — got a plate for us?"
        case .soft:
            return "What’s up, bud? I’ve gone a bit soft with you. Still here."
        case .strong:
            return "What’s up, bud? Feeling solid — protein’s been in the mix."
        case .balanced:
            return "What’s up, bud? Ready to plan or log whenever you are."
        }
    }

    static func offlineReply(message: String, ctx: Context) -> String {
        let q = message.lowercased()
        if q.contains("protein") {
            return "Protein helps you keep muscle while calories do the big body-change work. Hit a solid amount most days — perfection optional."
        }
        if q.contains("hungry") || q.contains("hunger") {
            return "Hunger’s normal in a cut. Volume foods and patience help. I’m mirroring you — if I’m hungry, you might be under target."
        }
        if q.contains("plan") {
            return "Plan something you’ll actually eat, then snap it when it’s real. Calories first; fancy timing later."
        }
        if ctx.reflection.form == .hungry {
            return "I’m a bit hollow over here. Log a plate when you can — we’ll straighten the day out."
        }
        return "Got it. Keep logging plates; calories steer the ship. I’m with you."
    }
}
