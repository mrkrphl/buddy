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
