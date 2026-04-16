import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var settings = AppSettings.shared
    @State private var notificationStatus: String = "checking..."

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
                if notificationStatus == "granted" {
                    HStack {
                        Text("Notifications enabled")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityLabel("enabled")
                    }
                } else if notificationStatus == "denied" {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Denied — open Settings")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Button("Request Notification Permission") {
                        Task {
                            let service = NotificationService()
                            _ = try? await service.requestPermission()
                            await checkNotificationStatus()
                        }
                    }
                    .font(.system(.body, design: .monospaced))

                    if notificationStatus != "checking..." {
                        Text(notificationStatus)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("MyMedTimer v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await checkNotificationStatus() }
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                notificationStatus = "granted"
            case .denied:
                notificationStatus = "denied"
            case .notDetermined:
                notificationStatus = "not determined"
            @unknown default:
                notificationStatus = "unknown"
            }
        }
    }
}
