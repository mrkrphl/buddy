import Foundation

/// Chat / check-in prompt pack — RP-grounded food & fitness companion (local FM).
enum BuddyTalkBeat {
    /// Matches the Settings stepper. Not a medical range.
    static let calorieFloor = 1200
    static let calorieCeiling = 4500

    struct Context {
        var caloriesToday: Int
        var target: Int
        var plateCount: Int
        var reflection: BuddyReflection
        var plannedTitles: [String]
    }

    /// Aside woven into the opening when a caller knows an intention.
    /// Trunk does not store one yet, so the app omits it.
    enum TalkIntention: Equatable {
        case seeWhatIEat
        case lose
        case gain

        var aside: String {
            switch self {
            case .seeWhatIEat:
                return "Curious mode on — we’ll just see what’s on the plate."
            case .lose:
                return "We’re aiming lighter. Calories first, no shame."
            case .gain:
                return "Fuel-up mode. Let’s get energy in."
            }
        }
    }

    /// Asks the app answers from plates, plans, and the calorie target
    /// before free-form chat.
    enum LocalChatIntent: Equatable {
        case today
        case eat
        case logPlate
        case explainTarget
        case requestGoalChange
        case proposeGoal(kcal: Int)
    }

    enum ChatTurn: Equatable {
        case say(String)
        case confirmGoal(kcal: Int, message: String)
        case confirmLog(message: String)
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
        If they ask how today is going, or what to eat, the app already answered from the log and the plan. Do not invent a medical read.
        """
    }

    static func parseLocalIntent(_ message: String) -> LocalChatIntent? {
        let q = message
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }
        if isLogAsk(q) { return .logPlate }
        if let goal = goalIntent(q) { return goal }
        if isTodayAsk(q) { return .today }
        if isEatAsk(q) { return .eat }
        return nil
    }

    static func resolve(_ intent: LocalChatIntent, ctx: Context) -> ChatTurn {
        switch intent {
        case .today:
            return .say(todayLine(ctx))
        case .eat:
            return .say(eatLine(ctx))
        case .logPlate:
            return .confirmLog(message: "Let’s log it. Confirm below, then open Today and hit Log plate — snap, library, or live AR.")
        case .explainTarget:
            return .say("Your daily energy target is \(formatKcal(ctx.target)) kcal — set from Settings or chat. It’s a starting point, not a lab calc. Want a different number? Say “set goal to 1800” and I’ll confirm.")
        case .requestGoalChange:
            return .say("Yeah — I can update your daily calorie goal. What number do you want? I keep it between \(formatKcal(calorieFloor)) and \(formatKcal(calorieCeiling)).")
        case .proposeGoal(let kcal):
            if kcal == ctx.target {
                return .say("You’re already at \(formatKcal(kcal)) kcal. Want a different target?")
            }
            return .confirmGoal(
                kcal: kcal,
                message: "Set your daily goal to \(formatKcal(kcal)) kcal? Confirm below and I’ll update Today."
            )
        }
    }

    static func userPrompt(_ message: String) -> String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func openingLine(reflection: BuddyReflection, intention: TalkIntention? = nil) -> String {
        let base: String
        switch reflection.form {
        case .hungry:
            base = "What’s up, bud? I’m running light — got a plate for us?"
        case .soft:
            base = "What’s up, bud? I’ve gone a bit soft with you. Still here."
        case .strong:
            base = "What’s up, bud? Feeling solid — protein’s been in the mix."
        case .balanced:
            base = "What’s up, bud? Ready to plan or log whenever you are."
        }
        guard let intention else { return base }
        return "\(base) \(intention.aside)"
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

    static func formatKcal(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
    }

    static func normalizeCalorieTarget(_ raw: Int) -> Int {
        let clamped = min(max(raw, calorieFloor), calorieCeiling)
        let rounded = Int((Double(clamped) / 50.0).rounded()) * 50
        return min(max(rounded, calorieFloor), calorieCeiling)
    }

    private static func todayLine(_ ctx: Context) -> String {
        let target = formatKcal(ctx.target)
        if ctx.plateCount == 0 {
            return "Zero plates so far, 0 kcal. Target is \(target) kcal."
        }
        let noun = ctx.plateCount == 1 ? "plate" : "plates"
        return "\(formatKcal(ctx.caloriesToday)) kcal so far across \(ctx.plateCount) \(noun). Target is \(target) kcal."
    }

    private static func eatLine(_ ctx: Context) -> String {
        let title = ctx.plannedTitles.first {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if let title {
            return "You’ve got \(title) planned. Say “log a plate” when it’s real."
        }
        return "Nothing planned today. Say “log a plate” when food is in front of you."
    }

    private static func isTodayAsk(_ q: String) -> Bool {
        let phrases = [
            "how is today",
            "how's today",
            "hows today",
            "how is my day",
            "how's my day",
            "hows my day",
            "how is the day",
            "how's the day",
            "hows the day",
            "how’s today",
            "how’s my day",
            "how’s the day",
        ]
        return phrases.contains { q.contains($0) }
    }

    private static func isEatAsk(_ q: String) -> Bool {
        let phrases = [
            "what should i eat",
            "what should i have",
            "what to eat",
            "what can i eat",
            "what do i eat",
        ]
        return phrases.contains { q.contains($0) }
    }

    private static func isLogAsk(_ q: String) -> Bool {
        let wantsLog = q.contains("log a plate") || q.contains("log plate")
            || q.contains("snap a plate") || q.contains("snap plate")
            || q.contains("log food") || q.contains("log my food")
            || q.contains("log something") || q.contains("take a photo")
            || (q.contains("log") && (q.contains("meal") || q.contains("eat") || q.contains("food") || q.contains("plate")))
            || (q.contains("snap") && (q.contains("food") || q.contains("meal") || q.contains("plate")))
        if wantsLog && !(q.contains("goal") || q.contains("target") || q.contains("calorie goal")) {
            return true
        }
        return false
    }

    private static func goalIntent(_ q: String) -> LocalChatIntent? {
        let asksWhy = q.contains("why") || q.contains("how come") || q.contains("what's with")
            || q.contains("whats with") || q.contains("what’s with")
        let mentionsDefault = q.contains("2200") || q.contains("2,200") || q.contains("default")
        let mentionsGoal = q.contains("goal") || q.contains("target") || q.contains("calorie")
            || q.contains("kcal") || q.contains("intake") || q.contains("energy")

        if asksWhy && (mentionsDefault || mentionsGoal) {
            return .explainTarget
        }

        let wantsChange = q.contains("change") || q.contains("set") || q.contains("update")
            || q.contains("adjust") || q.contains("make my") || q.contains("switch")
        guard wantsChange && mentionsGoal else { return nil }
        if let kcal = extractCalorieTarget(from: q) {
            return .proposeGoal(kcal: kcal)
        }
        return .requestGoalChange
    }

    private static func extractCalorieTarget(from message: String) -> Int? {
        let pattern = #"(?<!\d)(\d{1,2}(?:,\d{3})+|\d{3,5})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(message.startIndex..<message.endIndex, in: message)
        let matches = regex.matches(in: message, range: range)
        for match in matches {
            guard let swiftRange = Range(match.range(at: 1), in: message) else { continue }
            let digits = message[swiftRange].replacingOccurrences(of: ",", with: "")
            guard let raw = Int(digits), (1000...5000).contains(raw) else { continue }
            return normalizeCalorieTarget(raw)
        }
        return nil
    }
}
