import XCTest
import SwiftData
@testable import MyMedTimer

@MainActor
final class MedicationTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = container.mainContext
    }

    func testCreateMedication() {
        let med = Medication(name: "Metformin", dosage: "500mg")
        context.insert(med)

        XCTAssertEqual(med.name, "Metformin")
        XCTAssertEqual(med.dosage, "500mg")
        XCTAssertEqual(med.colorHex, "#FF6B6B")
        XCTAssertEqual(med.alertStyle, "gentle")
        XCTAssertTrue(med.isActive)
        XCTAssertEqual(med.scheduleTimes.count, 0)
        XCTAssertEqual(med.doseLogs.count, 0)
    }

    func testMedicationWithScheduleTimes() {
        let med = Medication(name: "Vitamin D", dosage: "1000IU")
        context.insert(med)

        let morning = ScheduleTime(hour: 8, minute: 0)
        let evening = ScheduleTime(hour: 20, minute: 0)
        med.scheduleTimes = [morning, evening]

        XCTAssertEqual(med.scheduleTimes.count, 2)
    }

    func testCascadeDeleteRemovesScheduleTimes() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 9, minute: 30)
        med.scheduleTimes = [schedule]
        try context.save()

        context.delete(med)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ScheduleTime>())
        XCTAssertEqual(remaining.count, 0)
    }

    func testCascadeDeleteRemovesDoseLogs() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let log = DoseLog(scheduledTime: Date(), status: "taken")
        med.doseLogs = [log]
        try context.save()

        context.delete(med)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<DoseLog>())
        XCTAssertEqual(remaining.count, 0)
    }
}
