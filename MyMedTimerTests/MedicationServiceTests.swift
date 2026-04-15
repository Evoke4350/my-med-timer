import XCTest
import SwiftData
@testable import MyMedTimer

@MainActor
final class MedicationServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = container.mainContext
    }

    func testNextDoseTimeForUpcomingSchedule() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 23, minute: 59)
        med.scheduleTimes = [schedule]

        let now = calendar(hour: 8, minute: 0)
        let next = MedicationService.nextDoseTime(for: med, after: now)

        XCTAssertNotNil(next)
        let components = Calendar.current.dateComponents([.hour, .minute], from: next!)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
    }

    func testNextDoseTimeWrapsToTomorrow() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 6, minute: 0)
        med.scheduleTimes = [schedule]

        let now = calendar(hour: 20, minute: 0)
        let next = MedicationService.nextDoseTime(for: med, after: now)

        XCTAssertNotNil(next)
        let nowDay = Calendar.current.component(.day, from: now)
        let nextDay = Calendar.current.component(.day, from: next!)
        XCTAssertNotEqual(nowDay, nextDay, "Next dose should be on a different calendar day")
        XCTAssertTrue(next! > now, "Next dose should be after now")
        let components = Calendar.current.dateComponents([.hour, .minute], from: next!)
        XCTAssertEqual(components.hour, 6)
        XCTAssertEqual(components.minute, 0)
    }

    func testNextDoseTimePicksEarliest() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let morning = ScheduleTime(hour: 8, minute: 0)
        let noon = ScheduleTime(hour: 12, minute: 0)
        let evening = ScheduleTime(hour: 20, minute: 0)
        med.scheduleTimes = [morning, noon, evening]

        let now = calendar(hour: 10, minute: 0)
        let next = MedicationService.nextDoseTime(for: med, after: now)

        XCTAssertNotNil(next)
        let components = Calendar.current.dateComponents([.hour, .minute], from: next!)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 0)
    }

    func testNextDoseTimeNoSchedule() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let next = MedicationService.nextDoseTime(for: med, after: Date())
        XCTAssertNil(next)
    }

    func testSortByNextDose() {
        let med1 = Medication(name: "Evening", dosage: "1mg")
        let med2 = Medication(name: "Morning", dosage: "1mg")
        context.insert(med1)
        context.insert(med2)

        med1.scheduleTimes = [ScheduleTime(hour: 20, minute: 0)]
        med2.scheduleTimes = [ScheduleTime(hour: 8, minute: 0)]

        let now = calendar(hour: 7, minute: 0)
        let sorted = MedicationService.sortedByNextDose([med1, med2], after: now)

        XCTAssertEqual(sorted[0].name, "Morning")
        XCTAssertEqual(sorted[1].name, "Evening")
    }

    // MARK: - Helpers

    private func calendar(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }
}
