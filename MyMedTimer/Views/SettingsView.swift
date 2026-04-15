import SwiftUI

struct SettingsView: View {
    @State private var settings = AppSettings.shared

    private let snoozeOptions = [5, 10, 15, 30]
    private let nagOptions = [3, 5, 10, 15]
    private let alertStyles = ["gentle", "urgent", "escalating"]

    var body: some View {
        Form {
            Section("defaults") {
                Picker("Snooze Duration", selection: $settings.defaultSnoozeMinutes) {
                    ForEach(snoozeOptions, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }
                .font(.system(.body, design: .monospaced))

                Picker("Nag Interval", selection: $settings.nagIntervalMinutes) {
                    ForEach(nagOptions, id: \.self) { mins in
                        Text("\(mins) min").tag(mins)
                    }
                }
                .font(.system(.body, design: .monospaced))

                Picker("Alert Style", selection: $settings.defaultAlertStyle) {
                    ForEach(alertStyles, id: \.self) { style in
                        Text(style).tag(style)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }

            Section("notifications") {
                Button("Request Notification Permission") {
                    Task {
                        let service = NotificationService()
                        _ = try? await service.requestPermission()
                    }
                }
                .font(.system(.body, design: .monospaced))
            }

            Section {
                Text("MyMedTimer v1.0.0")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
