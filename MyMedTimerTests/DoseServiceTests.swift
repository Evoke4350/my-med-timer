import XCTest
import SwiftData
@testable import MyMedTimer

@MainActor
final class DoseServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = container.mainContext
    }

    func testLogDoseTaken() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        let scheduledTime = Date()
        DoseService.logDose(for: med, scheduledTime: scheduledTime, status: "taken", in: context)

        XCTAssertEqual(med.doseLogs.count, 1)
        XCTAssertEqual(med.doseLogs.first?.status, "taken")
        XCTAssertNotNil(med.doseLogs.first?.actualTime)
    }

    func testLogDoseSkipped() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        DoseService.logDose(for: med, scheduledTime: Date(), status: "skipped", in: context)

        XCTAssertEqual(med.doseLogs.first?.status, "skipped")
        XCTAssertNil(med.doseLogs.first?.actualTime)
    }

    func testLogDoseSnoozed() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        DoseService.logDose(for: med, scheduledTime: Date(), status: "snoozed", in: context)

        XCTAssertEqual(med.doseLogs.first?.status, "snoozed")
    }

    func testMultipleDoseLogs() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        DoseService.logDose(for: med, scheduledTime: Date(), status: "taken", in: context)
        DoseService.logDose(for: med, scheduledTime: Date(), status: "skipped", in: context)

        XCTAssertEqual(med.doseLogs.count, 2)
    }

    func testTodaysDoseLogs() throws {
        let med = Medication(name: "Test", dosage: "1mg")
        context.insert(med)

        DoseService.logDose(for: med, scheduledTime: Date(), status: "taken", in: context)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let oldLog = DoseLog(scheduledTime: yesterday, status: "taken", actualTime: yesterday)
        med.doseLogs.append(oldLog)

        let todaysLogs = DoseService.todaysLogs(for: med)
        XCTAssertEqual(todaysLogs.count, 1)
    }
}
