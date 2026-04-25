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

    // MARK: - mostRecentScheduledDose Tests

    func testMostRecentScheduledDoseReturnsTodaySlot() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)
        med.scheduleTimes = [ScheduleTime(hour: 8, minute: 0)]

        let now = calendar(hour: 8, minute: 30)
        let recent = MedicationService.mostRecentScheduledDose(for: med, before: now)

        XCTAssertNotNil(recent)
        let components = Calendar.current.dateComponents([.hour, .minute], from: recent!)
        XCTAssertEqual(components.hour, 8)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(recent! < now)
    }

    func testMostRecentScheduledDoseRespectsWindow() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)
        med.scheduleTimes = [ScheduleTime(hour: 8, minute: 0)]

        let now = calendar(hour: 21, minute: 0) // 13h after the 8:00 slot
        let recent = MedicationService.mostRecentScheduledDose(for: med, before: now)

        XCTAssertNil(recent)
    }

    func testMostRecentScheduledDoseFallsBackToYesterday() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)
        med.scheduleTimes = [ScheduleTime(hour: 22, minute: 0)]

        let now = calendar(hour: 2, minute: 0)
        let recent = MedicationService.mostRecentScheduledDose(for: med, before: now)

        XCTAssertNotNil(recent)
        let components = Calendar.current.dateComponents([.hour, .minute], from: recent!)
        XCTAssertEqual(components.hour, 22)
        XCTAssertEqual(components.minute, 0)
        XCTAssertTrue(recent! < now)
    }

    func testMostRecentScheduledDosePRN() {
        let med = Medication(name: "Test", dosage: "1mg")
        med.isPRN = true
        context.insert(med)
        med.scheduleTimes = [ScheduleTime(hour: 8, minute: 0)]

        let now = calendar(hour: 8, minute: 30)
        XCTAssertNil(MedicationService.mostRecentScheduledDose(for: med, before: now))
    }

    func testMostRecentScheduledDosePicksLatestPastSlot() {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)
        med.scheduleTimes = [
            ScheduleTime(hour: 8, minute: 0),
            ScheduleTime(hour: 12, minute: 0),
            ScheduleTime(hour: 20, minute: 0),
        ]

        let now = calendar(hour: 14, minute: 0)
        let recent = MedicationService.mostRecentScheduledDose(for: med, before: now)

        XCTAssertNotNil(recent)
        let components = Calendar.current.dateComponents([.hour, .minute], from: recent!)
        XCTAssertEqual(components.hour, 12)
    }

    // MARK: - PRN Tests

    func testLastTakenTimeReturnsLatestTaken() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        context.insert(med)

        let earlier = Date().addingTimeInterval(-7200)
        let later = Date().addingTimeInterval(-3600)

        let log1 = DoseLog(scheduledTime: earlier, status: "taken")
        log1.actualTime = earlier
        let log2 = DoseLog(scheduledTime: later, status: "taken")
        log2.actualTime = later
        let log3 = DoseLog(scheduledTime: later, status: "skipped")
        log3.actualTime = later.addingTimeInterval(60)

        med.doseLogs = [log1, log2, log3]

        let last = MedicationService.lastTakenTime(for: med)
        XCTAssertNotNil(last)
        XCTAssertEqual(last!.timeIntervalSince1970, later.timeIntervalSince1970, accuracy: 1)
    }

    func testLastTakenTimeNilWhenNeverTaken() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        context.insert(med)

        XCTAssertNil(MedicationService.lastTakenTime(for: med))
    }

    func testCanTakePRNNoInterval() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        med.minIntervalMinutes = 0
        context.insert(med)

        XCTAssertTrue(MedicationService.canTakePRN(med))
    }

    func testCanTakePRNIntervalNotElapsed() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        med.minIntervalMinutes = 240 // 4 hours
        context.insert(med)

        let log = DoseLog(scheduledTime: Date(), status: "taken")
        log.actualTime = Date().addingTimeInterval(-3600) // 1 hour ago
        med.doseLogs = [log]

        let now = Date()
        XCTAssertFalse(MedicationService.canTakePRN(med, now: now))
    }

    func testCanTakePRNIntervalElapsed() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        med.minIntervalMinutes = 60 // 1 hour
        context.insert(med)

        let log = DoseLog(scheduledTime: Date(), status: "taken")
        log.actualTime = Date().addingTimeInterval(-7200) // 2 hours ago
        med.doseLogs = [log]

        let now = Date()
        XCTAssertTrue(MedicationService.canTakePRN(med, now: now))
    }

    func testMinutesUntilCanTake() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        med.minIntervalMinutes = 240 // 4 hours
        context.insert(med)

        let log = DoseLog(scheduledTime: Date(), status: "taken")
        log.actualTime = Date().addingTimeInterval(-3600) // 1 hour ago
        med.doseLogs = [log]

        let now = Date()
        let mins = MedicationService.minutesUntilCanTake(med, now: now)
        XCTAssertEqual(mins, 180) // 3 hours remaining
    }

    func testCanTakePRNNeverTaken() {
        let med = Medication(name: "PRN Med", dosage: "10mg")
        med.isPRN = true
        med.minIntervalMinutes = 240
        context.insert(med)

        XCTAssertTrue(MedicationService.canTakePRN(med))
        XCTAssertEqual(MedicationService.minutesUntilCanTake(med), 0)
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
