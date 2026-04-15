import Foundation
import SwiftData
@testable import MyMedTimer

@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Medication.self, ScheduleTime.self, DoseLog.self,
        configurations: config
    )
}
