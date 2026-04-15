import XCTest
import UserNotifications
@testable import MyMedTimer

final class MockNotificationCenter: NotificationCenterProtocol, @unchecked Sendable {
    var pendingRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []
    var authorizationGranted = true

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return authorizationGranted
    }

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
        pendingRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func removeAllPendingNotificationRequests() {
        pendingRequests.removeAll()
    }
}

final class NotificationServiceTests: XCTestCase {
    var mockCenter: MockNotificationCenter!
    var service: NotificationService!

    override func setUp() {
        mockCenter = MockNotificationCenter()
        service = NotificationService(center: mockCenter)
    }

    func testScheduleNotification() async throws {
        try await service.scheduleNotification(
            id: "med-123-08:00",
            title: "Metformin",
            body: "500mg — time to take your dose",
            hour: 8,
            minute: 0
        )

        XCTAssertEqual(mockCenter.pendingRequests.count, 1)
        let request = mockCenter.pendingRequests[0]
        XCTAssertEqual(request.identifier, "med-123-08:00")
        XCTAssertEqual(request.content.title, "Metformin")

        let trigger = request.trigger as? UNCalendarNotificationTrigger
        XCTAssertNotNil(trigger)
        XCTAssertEqual(trigger?.dateComponents.hour, 8)
        XCTAssertEqual(trigger?.dateComponents.minute, 0)
        XCTAssertTrue(trigger?.repeats ?? false)
    }

    func testCancelNotification() {
        service.cancelNotification(id: "med-123-08:00")
        XCTAssertEqual(mockCenter.removedIdentifiers, ["med-123-08:00"])
    }

    func testCancelAllNotifications() {
        service.cancelAll()
        XCTAssertTrue(mockCenter.pendingRequests.isEmpty)
    }

    func testScheduleAllForMedication() async throws {
        try await service.scheduleAll(
            medicationId: "abc",
            name: "Vitamin D",
            dosage: "1000IU",
            times: [(hour: 8, minute: 0), (hour: 20, minute: 0)]
        )

        XCTAssertEqual(mockCenter.pendingRequests.count, 2)
    }
}
