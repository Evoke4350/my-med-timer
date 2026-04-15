import Foundation
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var defaultSnoozeMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "defaultSnoozeMinutes").nonZero ?? 10 }
        set { UserDefaults.standard.set(newValue, forKey: "defaultSnoozeMinutes") }
    }

    var nagIntervalMinutes: Int {
        get { UserDefaults.standard.integer(forKey: "nagIntervalMinutes").nonZero ?? 5 }
        set { UserDefaults.standard.set(newValue, forKey: "nagIntervalMinutes") }
    }

    var defaultAlertStyle: String {
        get { UserDefaults.standard.string(forKey: "defaultAlertStyle") ?? "gentle" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultAlertStyle") }
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
