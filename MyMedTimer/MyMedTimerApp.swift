import SwiftUI
import SwiftData

@main
struct MyMedTimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Medication.self, ScheduleTime.self, DoseLog.self])
    }
}

struct ContentView: View {
    var body: some View {
        Text("MyMedTimer")
            .font(.system(.title, design: .monospaced))
    }
}
