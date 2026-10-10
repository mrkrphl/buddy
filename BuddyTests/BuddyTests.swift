import XCTest
@testable import Buddy

final class BuddyTests: XCTestCase {
    func testBuddyPeerIdentity_isNotDietCoach() {
        let id = BuddyPeerBase.identity
        let lower = id.lowercased()
        XCTAssertTrue(id.contains("Buddy"))
        XCTAssertTrue(lower.contains("ghost"))
        XCTAssertTrue(lower.contains("never shame"))
        XCTAssertTrue(lower.contains("never diagnose"))
        // "As an AI" appears only as a banned opener, not as self-description.
        XCTAssertTrue(id.contains("Don't open with:"))
        XCTAssertTrue(id.contains("As an AI"))
    }

    func testMealJSONParse() {
        let raw = """
        {"title":"Rice bowl","calories":520,"proteinG":22,"carbsG":68,"fatG":14,"confidence":0.7,"buddyLine":"Looking solid."}
        """
        let e = MealWatchService.parseJSON(raw, usedFM: true)
        XCTAssertEqual(e?.title, "Rice bowl")
        XCTAssertEqual(e?.calories, 520)
        XCTAssertEqual(e?.usedFoundationModels, true)
    }

    func testOfflineEstimate_salad() {
        let day = MealWatchBeat.DayContext(caloriesSoFar: 0, target: 2200, plateCount: 0, userHint: "big salad")
        let e = MealWatchService.offlineEstimate(plateDescription: "", day: day)
        XCTAssertTrue(e.title.lowercased().contains("salad"))
        XCTAssertGreaterThan(e.calories, 0)
        XCTAssertFalse(e.usedFoundationModels)
    }

    func testProgressAwardsStreakAndLevel() {
        let p = BuddyProgress(xp: 0, level: 1, streakDays: 0, lastWatchDayKey: "", mood: .curious)
        p.awardWatch(on: "2026-09-22", xpGain: 15)
        p.awardWatch(on: "2026-09-23", xpGain: 15)
        XCTAssertEqual(p.streakDays, 2)
        XCTAssertEqual(p.lastWatchDayKey, "2026-09-23")
    }

    func testReflection_hungryWhenEmptyAfternoon() {
        let afternoon = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
        let r = BuddyReflection.compute(plates: [], dailyTarget: 2200, now: afternoon)
        XCTAssertEqual(r.form, .hungry)
        XCTAssertGreaterThanOrEqual(r.hunger, 0.55)
    }

    func testReflection_softOnSurplus() {
        let now = Date()
        // ~1.3× target over 3 days with fat-forward plates
        let plates = (0..<6).map { i in
            PlateSnapshot(
                createdAt: Calendar.current.date(byAdding: .hour, value: -i * 8, to: now)!,
                calories: 1300,
                proteinG: 25,
                fatG: 70
            )
        }
        let r = BuddyReflection.compute(plates: plates, dailyTarget: 2000, now: now)
        XCTAssertGreaterThan(r.softness, 0.4)
        XCTAssertEqual(r.form, .soft)
    }

    func testReflection_strongOnProteinNearTarget() {
        let now = Date()
        // Near target (~1.0) with high protein share
        let plates = (0..<6).map { i in
            PlateSnapshot(
                createdAt: Calendar.current.date(byAdding: .hour, value: -i * 8, to: now)!,
                calories: 1050,
                proteinG: 70,
                fatG: 22
            )
        }
        let r = BuddyReflection.compute(plates: plates, dailyTarget: 2100, now: now)
        XCTAssertGreaterThanOrEqual(r.muscle, 0.5)
        XCTAssertEqual(r.form, .strong)
    }

    func testTalkOpening_matchesForm() {
        let hungry = BuddyReflection(hunger: 0.8, softness: 0.1, muscle: 0.1)
        XCTAssertTrue(BuddyTalkBeat.openingLine(reflection: hungry).lowercased().contains("light"))
    }

    func testTalkOpening_loseAndGainAsides() {
        let balanced = BuddyReflection(hunger: 0.2, softness: 0.2, muscle: 0.2)
        XCTAssertEqual(
            BuddyTalkBeat.openingLine(reflection: balanced, intention: .lose),
            "What’s up, bud? Ready to plan or log whenever you are. We’re aiming lighter. Calories first, no shame."
        )
        XCTAssertEqual(
            BuddyTalkBeat.openingLine(reflection: balanced, intention: .gain),
            "What’s up, bud? Ready to plan or log whenever you are. Fuel-up mode. Let’s get energy in."
        )
    }

    func testHowIsToday_namesCaloriesAndTarget() async {
        let empty = BuddyTalkBeat.Context(
            caloriesToday: 0,
            target: 2200,
            plateCount: 0,
            reflection: .neutral,
            plannedTitles: []
        )
        let emptyTurn = await BuddyChatService.reply(message: "how is today", ctx: empty)
        XCTAssertEqual(emptyTurn, .say("Zero plates so far, 0 kcal. Target is 2,200 kcal."))

        var logged = empty
        logged.caloriesToday = 520
        logged.plateCount = 1
        let loggedTurn = await BuddyChatService.reply(message: "how is today", ctx: logged)
        XCTAssertEqual(loggedTurn, .say("520 kcal so far across 1 plate. Target is 2,200 kcal."))
    }

    func testWhatShouldIEat_usesPlanTitle() async {
        let planned = BuddyTalkBeat.Context(
            caloriesToday: 0,
            target: 2200,
            plateCount: 0,
            reflection: .neutral,
            plannedTitles: ["Rice bowl"]
        )
        let plannedTurn = await BuddyChatService.reply(message: "what should I eat", ctx: planned)
        XCTAssertEqual(
            plannedTurn,
            .say("You’ve got Rice bowl planned. Say “log a plate” when it’s real.")
        )

        var bare = planned
        bare.plannedTitles = []
        let bareTurn = await BuddyChatService.reply(message: "what should I eat", ctx: bare)
        XCTAssertEqual(
            bareTurn,
            .say("Nothing planned today. Say “log a plate” when food is in front of you.")
        )
    }

    func testLogAndGoalIntents_offerConfirm() async {
        let ctx = BuddyTalkBeat.Context(
            caloriesToday: 0,
            target: 2200,
            plateCount: 0,
            reflection: .neutral,
            plannedTitles: []
        )
        let log = await BuddyChatService.reply(message: "log a plate", ctx: ctx)
        XCTAssertEqual(
            log,
            .confirmLog(message: "Let’s log it. Confirm below, then open Today and hit Log plate — snap, library, or live AR.")
        )
        let goal = await BuddyChatService.reply(message: "set goal to 1800", ctx: ctx)
        XCTAssertEqual(
            goal,
            .confirmGoal(
                kcal: 1800,
                message: "Set your daily goal to 1,800 kcal? Confirm below and I’ll update Today."
            )
        )
        XCTAssertNil(BuddyTalkBeat.parseLocalIntent("I ate about 1800 calories for lunch"))
        XCTAssertEqual(BuddyTalkBeat.parseLocalIntent("set goal to 1,850 kcal"), .proposeGoal(kcal: 1850))
    }

    func testNormalizeCalorieTarget_clampsAndRounds() {
        XCTAssertEqual(BuddyTalkBeat.normalizeCalorieTarget(1833), 1850)
        XCTAssertEqual(BuddyTalkBeat.normalizeCalorieTarget(900), 1200)
        XCTAssertEqual(BuddyTalkBeat.normalizeCalorieTarget(6000), 4500)
    }

    @MainActor
    func testRouter_openTodayPulsesLog() {
        let router = BuddyRouter()
        router.selectedTab = 2
        router.openTodayForLogging()
        XCTAssertEqual(router.selectedTab, 0)
        XCTAssertEqual(router.logPlatePulseToken, 1)
    }

    func testReflection_superHungryFlag() {
        let mild = BuddyReflection(hunger: 0.6, softness: 0.1, muscle: 0.1)
        let melted = BuddyReflection(hunger: 0.85, softness: 0.1, muscle: 0.1)
        XCTAssertFalse(mild.isSuperHungry)
        XCTAssertTrue(melted.isSuperHungry)
        XCTAssertTrue(melted.blurb.lowercased().contains("wilted"))
    }

    func testKitchenApplianceStore_roundTrip() {
        let set: Set<KitchenApplianceID> = [.airFryer, .stove, .blender]
        let encoded = KitchenApplianceStore.encodeIDs(set)
        XCTAssertEqual(encoded, ["stove", "airFryer", "blender"])
        let decoded = KitchenApplianceStore.decodeIDs(encoded + ["nope"])
        XCTAssertEqual(decoded, set)
    }

    func testPreferences_applianceNotes() {
        let p = BuddyPreferences()
        p.setNote("  crispy fries  ", for: .airFryer)
        XCTAssertEqual(p.note(for: .airFryer), "crispy fries")
        p.setNote("   ", for: .airFryer)
        XCTAssertEqual(p.note(for: .airFryer), "")
        p.ownedAppliances = [.microwave, .oven]
        XCTAssertTrue(p.ownedApplianceIDs.contains("microwave"))
        XCTAssertEqual(p.ownedAppliances.count, 2)
    }
}
