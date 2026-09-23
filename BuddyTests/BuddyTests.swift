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
}
