import XCTest
import SwiftData
@testable import MyMedTimer

// MARK: - CircularStatistics Tests

final class CircularStatisticsTests: XCTestCase {

    let accuracy = 0.01

    // MARK: timeToAngle

    func testTimeToAngleMidnight() {
        let angle = CircularStatistics.timeToAngle(hour: 0, minute: 0)
        XCTAssertEqual(angle, 0, accuracy: accuracy)
    }

    func testTimeToAngle6AM() {
        let angle = CircularStatistics.timeToAngle(hour: 6, minute: 0)
        XCTAssertEqual(angle, .pi / 2, accuracy: accuracy)
    }

    func testTimeToAngleNoon() {
        let angle = CircularStatistics.timeToAngle(hour: 12, minute: 0)
        XCTAssertEqual(angle, .pi, accuracy: accuracy)
    }

    func testTimeToAngle6PM() {
        let angle = CircularStatistics.timeToAngle(hour: 18, minute: 0)
        XCTAssertEqual(angle, 3 * .pi / 2, accuracy: accuracy)
    }

    // MARK: angleToTime

    func testAngleToTimeRoundTrip() {
        let testCases: [(Int, Int)] = [(0, 0), (6, 0), (12, 0), (18, 0), (8, 30), (23, 45), (14, 15)]
        for (h, m) in testCases {
            let angle = CircularStatistics.timeToAngle(hour: h, minute: m)
            let result = CircularStatistics.angleToTime(angle)
            XCTAssertEqual(result.hour, h, "Hour mismatch for \(h):\(m)")
            XCTAssertEqual(result.minute, m, "Minute mismatch for \(h):\(m)")
        }
    }

    func testAngleToTimeNegativeAngle() {
        // Negative angle should normalize to [0, 2π)
        let result = CircularStatistics.angleToTime(-(.pi / 2))
        XCTAssertEqual(result.hour, 18)
        XCTAssertEqual(result.minute, 0)
    }

    // MARK: circularMean

    func testCircularMeanMidnightWrap() {
        // Key test: [11pm, 1am] should give midnight, NOT noon
        let angle11pm = CircularStatistics.timeToAngle(hour: 23, minute: 0)
        let angle1am = CircularStatistics.timeToAngle(hour: 1, minute: 0)
        let mean = CircularStatistics.circularMean([angle11pm, angle1am])
        let time = CircularStatistics.angleToTime(mean)
        XCTAssertEqual(time.hour, 0, "Circular mean of 11pm and 1am should be midnight")
        XCTAssertEqual(time.minute, 0, accuracy: 1)
    }

    func testCircularMeanSameAngles() {
        let angle = CircularStatistics.timeToAngle(hour: 8, minute: 0)
        let mean = CircularStatistics.circularMean([angle, angle, angle])
        XCTAssertEqual(mean, angle, accuracy: accuracy)
    }

    func testCircularMeanEmpty() {
        let mean = CircularStatistics.circularMean([])
        XCTAssertEqual(mean, 0)
    }

    // MARK: meanResultantLength

    func testMeanResultantLengthIdentical() {
        let angle = CircularStatistics.timeToAngle(hour: 9, minute: 0)
        let rBar = CircularStatistics.meanResultantLength([angle, angle, angle])
        XCTAssertEqual(rBar, 1.0, accuracy: accuracy)
    }

    func testMeanResultantLengthOpposite() {
        // Two opposite angles should give R̄ ≈ 0
        let rBar = CircularStatistics.meanResultantLength([0, .pi])
        XCTAssertEqual(rBar, 0.0, accuracy: accuracy)
    }

    func testMeanResultantLengthEmpty() {
        XCTAssertEqual(CircularStatistics.meanResultantLength([]), 0)
    }

    // MARK: circularVariance

    func testCircularVarianceSameAngles() {
        let angle = CircularStatistics.timeToAngle(hour: 10, minute: 0)
        let variance = CircularStatistics.circularVariance([angle, angle, angle])
        XCTAssertEqual(variance, 0.0, accuracy: accuracy)
    }

    func testCircularVarianceUniformlySpread() {
        // Four equally spaced angles (0, π/2, π, 3π/2) → R̄ ≈ 0, variance ≈ 1
        let angles = [0.0, .pi / 2, .pi, 3 * .pi / 2]
        let variance = CircularStatistics.circularVariance(angles)
        XCTAssertEqual(variance, 1.0, accuracy: accuracy)
    }

    // MARK: vonMisesKappa

    func testVonMisesKappaHighConcentration() {
        // Identical angles → R̄ = 1.0 → very high κ
        let angle = CircularStatistics.timeToAngle(hour: 8, minute: 0)
        let angles = [angle, angle, angle, angle, angle]
        let kappa = CircularStatistics.vonMisesKappa(angles)
        XCTAssertGreaterThan(kappa, 10.0, "Identical angles should produce high κ")
    }

    func testVonMisesKappaLowConcentration() {
        // Spread out angles → low R̄ → low κ
        let angles = [0.0, .pi / 2, .pi, 3 * .pi / 2]
        let kappa = CircularStatistics.vonMisesKappa(angles)
        XCTAssertEqual(kappa, 0.0, accuracy: 0.1, "Uniformly spread angles should produce κ ≈ 0")
    }

    func testVonMisesKappaEmpty() {
        XCTAssertEqual(CircularStatistics.vonMisesKappa([]), 0)
    }

    // MARK: suggestedTime

    func testSuggestedTimeAroundEight() {
        // Doses at 7:50, 8:10, 7:55, 8:05 → suggests ~8:00
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let dates = [
            calendar.date(bySettingHour: 7, minute: 50, second: 0, of: base)!,
            calendar.date(bySettingHour: 8, minute: 10, second: 0, of: base)!,
            calendar.date(bySettingHour: 7, minute: 55, second: 0, of: base)!,
            calendar.date(bySettingHour: 8, minute: 5, second: 0, of: base)!,
        ]
        let result = CircularStatistics.suggestedTime(from: dates)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.hour, 8)
        XCTAssertEqual(result!.minute, 0, accuracy: 2)
    }

    func testSuggestedTimeEmpty() {
        XCTAssertNil(CircularStatistics.suggestedTime(from: []))
    }

    func testSuggestedTimeSingleDate() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let date = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: base)!
        let result = CircularStatistics.suggestedTime(from: [date])
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.hour, 14)
        XCTAssertEqual(result!.minute, 30)
    }

    // MARK: consistencyScore

    func testConsistencyScoreTightCluster() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let dates = (0..<10).map { i in
            calendar.date(bySettingHour: 9, minute: i % 3, second: 0, of: base.addingTimeInterval(Double(i) * 86400))!
        }
        let score = CircularStatistics.consistencyScore(from: dates)
        XCTAssertGreaterThan(score, 90, "Tight cluster should have high consistency")
    }

    func testConsistencyScoreScattered() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        // Spread across the day: 0, 6, 12, 18 hours
        let dates = [0, 6, 12, 18].map { hour in
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base)!
        }
        let score = CircularStatistics.consistencyScore(from: dates)
        XCTAssertLessThan(score, 10, "Scattered times should have low consistency")
    }

    func testConsistencyScoreEmpty() {
        XCTAssertEqual(CircularStatistics.consistencyScore(from: []), 0)
    }
}

// MARK: - HawkesProcess Tests

final class HawkesProcessTests: XCTestCase {

    let defaultParams = HawkesParameters(mu: 0.1, alpha: 0.3, beta: 1.0)

    // MARK: intensity

    func testIntensityNoMisses() {
        let now = Date()
        let lambda = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [])
        XCTAssertEqual(lambda, defaultParams.mu, accuracy: 0.001, "Intensity with no misses should equal baseline μ")
    }

    func testIntensityIncreasesAfterMiss() {
        let now = Date()
        let justMissed = now.addingTimeInterval(-3600) // 1 hour ago
        let lambda = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [justMissed])
        XCTAssertGreaterThan(lambda, defaultParams.mu, "Intensity should increase after a recent miss")
    }

    func testIntensityDecaysOverTime() {
        let now = Date()
        let recentMiss = now.addingTimeInterval(-3600)       // 1 hour ago
        let olderMiss = now.addingTimeInterval(-86400 * 7)   // 7 days ago

        let lambdaRecent = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [recentMiss])
        let lambdaOlder = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [olderMiss])

        XCTAssertGreaterThan(lambdaRecent, lambdaOlder, "Intensity from recent miss should be higher than from older miss")
    }

    func testIntensityMultipleMissesStack() {
        let now = Date()
        let miss1 = now.addingTimeInterval(-3600)
        let miss2 = now.addingTimeInterval(-7200)

        let lambdaSingle = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [miss1])
        let lambdaDouble = HawkesProcess.intensity(at: now, parameters: defaultParams, recentMisses: [miss1, miss2])

        XCTAssertGreaterThan(lambdaDouble, lambdaSingle, "Multiple misses should stack intensity")
    }

    // MARK: missProbability

    func testMissProbabilityRange() {
        let now = Date()
        let prob = HawkesProcess.missProbability(at: now, parameters: defaultParams, recentMisses: [])
        XCTAssertGreaterThanOrEqual(prob, 0.0)
        XCTAssertLessThanOrEqual(prob, 1.0)
    }

    func testMissProbabilityHigherAfterMiss() {
        let now = Date()
        let recentMiss = now.addingTimeInterval(-3600)
        let probNoMiss = HawkesProcess.missProbability(at: now, parameters: defaultParams, recentMisses: [])
        let probAfterMiss = HawkesProcess.missProbability(at: now, parameters: defaultParams, recentMisses: [recentMiss])
        XCTAssertGreaterThan(probAfterMiss, probNoMiss)
    }

    // MARK: riskLevel

    func testRiskLevelLow() {
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.1), .low)
    }

    func testRiskLevelMedium() {
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.3), .medium)
    }

    func testRiskLevelHigh() {
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.7), .high)
    }

    func testRiskLevelBoundaries() {
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.19), .low)
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.2), .medium)
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.5), .medium)
        XCTAssertEqual(HawkesProcess.riskLevel(missProbability: 0.51), .high)
    }

    // MARK: fit

    func testFitWithTooFewEvents() {
        let now = Date()
        let timestamps = [now, now.addingTimeInterval(-86400)]
        let params = HawkesProcess.fit(
            missTimestamps: timestamps,
            windowStart: now.addingTimeInterval(-86400 * 30),
            windowEnd: now
        )
        // Should return conservative defaults
        XCTAssertEqual(params.mu, 0.1, accuracy: 0.001)
        XCTAssertEqual(params.alpha, 0.3, accuracy: 0.001)
        XCTAssertEqual(params.beta, 1.0, accuracy: 0.001)
    }

    func testFitStationarityConstraint() {
        // Generate clustered events that might push alpha > beta
        let now = Date()
        let timestamps = (0..<20).map { i in
            now.addingTimeInterval(-Double(i) * 3600) // one per hour for 20 hours
        }
        let params = HawkesProcess.fit(
            missTimestamps: timestamps,
            windowStart: now.addingTimeInterval(-86400 * 30),
            windowEnd: now
        )
        XCTAssertLessThan(params.alpha, params.beta, "Stationarity: α must be < β")
    }

    func testFitPositiveParameters() {
        let now = Date()
        let timestamps = (0..<10).map { i in
            now.addingTimeInterval(-Double(i) * 86400 * 2) // every 2 days
        }
        let params = HawkesProcess.fit(
            missTimestamps: timestamps,
            windowStart: now.addingTimeInterval(-86400 * 30),
            windowEnd: now
        )
        XCTAssertGreaterThan(params.mu, 0)
        XCTAssertGreaterThan(params.alpha, 0)
        XCTAssertGreaterThan(params.beta, 0)
    }
}

// MARK: - AdherenceEngine Tests

@MainActor
final class AdherenceEngineTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        container = try makeTestContainer()
        context = container.mainContext
    }

    // MARK: whittleIndex

    func testWhittleIndexIncreasesWithMissProbability() {
        let lowRisk = AdherenceEngine.whittleIndex(missProbability: 0.1, importance: 1.0, recentEscalationCount: 0)
        let highRisk = AdherenceEngine.whittleIndex(missProbability: 0.8, importance: 1.0, recentEscalationCount: 0)
        XCTAssertGreaterThan(highRisk, lowRisk)
    }

    func testWhittleIndexDecreasesWithEscalations() {
        let noFatigue = AdherenceEngine.whittleIndex(missProbability: 0.5, importance: 1.0, recentEscalationCount: 0)
        let withFatigue = AdherenceEngine.whittleIndex(missProbability: 0.5, importance: 1.0, recentEscalationCount: 5)
        XCTAssertGreaterThan(noFatigue, withFatigue, "More escalations should reduce Whittle index due to fatigue cost")
    }

    func testWhittleIndexScalesWithImportance() {
        let low = AdherenceEngine.whittleIndex(missProbability: 0.5, importance: 0.5, recentEscalationCount: 0)
        let high = AdherenceEngine.whittleIndex(missProbability: 0.5, importance: 2.0, recentEscalationCount: 0)
        XCTAssertGreaterThan(high, low)
    }

    // MARK: recommendedAlertStyle

    func testRecommendedAlertStyleGentle() {
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.1), "gentle")
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.29), "gentle")
    }

    func testRecommendedAlertStyleUrgent() {
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.3), "urgent")
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.5), "urgent")
    }

    func testRecommendedAlertStyleEscalating() {
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.61), "escalating")
        XCTAssertEqual(AdherenceEngine.recommendedAlertStyle(whittleIndex: 0.9), "escalating")
    }

    // MARK: analyze

    func testAnalyzeAllTakenLowRisk() {
        let med = Medication(name: "Aspirin", dosage: "81mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 8, minute: 0)
        schedule.medication = med
        context.insert(schedule)

        let calendar = Calendar.current
        let now = Date()
        // Add 30 days of taken doses at consistent times
        for i in 0..<30 {
            let day = calendar.date(byAdding: .day, value: -i, to: now)!
            let scheduledTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day)!
            let actualTime = calendar.date(bySettingHour: 8, minute: Int.random(in: 0...5), second: 0, of: day)!
            let log = DoseLog(scheduledTime: scheduledTime, status: "taken", actualTime: actualTime)
            log.medication = med
            context.insert(log)
        }
        try? context.save()

        let insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: now)
        XCTAssertEqual(insight.riskLevel, .low, "Medication with all taken doses should be low risk")
        XCTAssertGreaterThan(insight.consistencyScore, 80, "Consistent timing should yield high consistency score")
        XCTAssertEqual(insight.recommendedAlertStyle, "gentle")
    }

    func testAnalyzeRecentSkipsElevatedRisk() {
        let med = Medication(name: "Statin", dosage: "20mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 21, minute: 0)
        schedule.medication = med
        context.insert(schedule)

        let calendar = Calendar.current
        let now = Date()
        // Add some taken doses and recent skips
        for i in 0..<30 {
            let day = calendar.date(byAdding: .day, value: -i, to: now)!
            let scheduledTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day)!
            let status: String
            if i < 5 {
                // Recent 5 days: all skipped
                status = "skipped"
            } else {
                status = "taken"
            }
            let log = DoseLog(scheduledTime: scheduledTime, status: status, actualTime: status == "taken" ? scheduledTime : nil)
            log.medication = med
            context.insert(log)
        }
        try? context.save()

        let insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: now)
        XCTAssertGreaterThan(insight.missProbability, 0.3, "Recent skips should elevate miss probability")
    }

    func testAnalyzeStaleMissReturnsLow() {
        let med = Medication(name: "Aspirin", dosage: "81mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 8, minute: 0)
        schedule.medication = med
        context.insert(schedule)

        let calendar = Calendar.current
        let now = Date()
        // One skip 30 days ago
        let oldSkipTime = calendar.date(byAdding: .day, value: -30, to: now)!
        let oldSkip = DoseLog(scheduledTime: oldSkipTime, status: "skipped")
        oldSkip.medication = med
        context.insert(oldSkip)
        // 20 takes since (every day for last 20 days, all in last 14d window — gate fires before override)
        for i in 0..<20 {
            let day = calendar.date(byAdding: .day, value: -i, to: now)!
            let scheduledTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day)!
            let log = DoseLog(scheduledTime: scheduledTime, status: "taken", actualTime: scheduledTime)
            log.medication = med
            context.insert(log)
        }
        try? context.save()

        let insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: now)
        XCTAssertEqual(insight.riskLevel, .low, "Stale (>14d) miss with recent clean takes should be .low")
    }

    func testAnalyzeSevenConsecutiveTakesOverride() {
        let med = Medication(name: "Statin", dosage: "20mg")
        context.insert(med)

        let schedule = ScheduleTime(hour: 21, minute: 0)
        schedule.medication = med
        context.insert(schedule)

        let calendar = Calendar.current
        let now = Date()
        // Skip 10 days ago at 21:00 — recent enough to be in 14d window so the
        // first gate (no misses in 14d) does NOT fire; only the streak gate can
        // green-light this.
        let skipDay = calendar.date(byAdding: .day, value: -10, to: now)!
        let skipTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: skipDay)!
        let skip = DoseLog(scheduledTime: skipTime, status: "skipped")
        skip.medication = med
        context.insert(skip)
        // 7 consecutive takes — all newer than the skip.
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: now)!
            let scheduledTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day)!
            let log = DoseLog(scheduledTime: scheduledTime, status: "taken", actualTime: scheduledTime)
            log.medication = med
            context.insert(log)
        }
        try? context.save()

        let insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: now)
        XCTAssertEqual(insight.riskLevel, .low, "Seven consecutive takes after a skip should override risk to .low")
    }

    func testAnalyzeEmptyLogs() {
        let med = Medication(name: "Vitamin D", dosage: "1000IU")
        context.insert(med)
        try? context.save()

        let insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: Date())
        XCTAssertEqual(insight.consistencyScore, 0)
        XCTAssertNil(insight.suggestedTime)
    }

    // MARK: analyzeAll

    func testAnalyzeAllSortsByRisk() {
        let med1 = Medication(name: "Med A", dosage: "10mg")
        let med2 = Medication(name: "Med B", dosage: "20mg")
        context.insert(med1)
        context.insert(med2)
        try? context.save()

        let insights = AdherenceEngine.analyzeAll(medications: [med1, med2])
        XCTAssertEqual(insights.count, 2)
        // Should be sorted by missProbability descending
        XCTAssertGreaterThanOrEqual(insights[0].missProbability, insights[1].missProbability)
    }

    func testAnalyzeAllFiltersInactive() {
        let active = Medication(name: "Active Med", dosage: "10mg")
        let inactive = Medication(name: "Inactive Med", dosage: "20mg")
        inactive.isActive = false
        context.insert(active)
        context.insert(inactive)
        try? context.save()

        let insights = AdherenceEngine.analyzeAll(medications: [active, inactive])
        XCTAssertEqual(insights.count, 1, "Inactive medications should be filtered out")
    }
}

// MARK: - XCTAssertEqual for Int with accuracy

private func XCTAssertEqual(_ a: Int, _ b: Int, accuracy: Int, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(abs(a - b) <= accuracy, "\(message) — expected \(b)±\(accuracy), got \(a)", file: file, line: line)
}
