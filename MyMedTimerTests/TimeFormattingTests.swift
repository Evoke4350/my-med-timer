import XCTest
@testable import MyMedTimer

final class TimeFormattingTests: XCTestCase {

    func testFormatCountdownHoursAndMinutes() {
        let interval: TimeInterval = 3 * 3600 + 45 * 60 // 3h 45m
        XCTAssertEqual(TimeFormatting.countdown(interval), "3h 45m")
    }

    func testFormatCountdownMinutesOnly() {
        let interval: TimeInterval = 12 * 60 + 30 // 12m 30s
        XCTAssertEqual(TimeFormatting.countdown(interval), "12m")
    }

    func testFormatCountdownUnderOneMinute() {
        let interval: TimeInterval = 45
        XCTAssertEqual(TimeFormatting.countdown(interval), "<1m")
    }

    func testFormatCountdownNegative() {
        let interval: TimeInterval = -300
        XCTAssertEqual(TimeFormatting.countdown(interval), "overdue")
    }

    func testFormatCountdownZero() {
        XCTAssertEqual(TimeFormatting.countdown(0), "now")
    }

    func testFormatTimeOfDay() {
        XCTAssertEqual(TimeFormatting.timeOfDay(hour: 8, minute: 0), "8:00 AM")
        XCTAssertEqual(TimeFormatting.timeOfDay(hour: 14, minute: 30), "2:30 PM")
        XCTAssertEqual(TimeFormatting.timeOfDay(hour: 0, minute: 0), "12:00 AM")
        XCTAssertEqual(TimeFormatting.timeOfDay(hour: 12, minute: 0), "12:00 PM")
    }
}
