import SwiftUI
import SwiftData

struct AddEditMedView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let medication: Medication?

    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var colorHex: String = "#FF6B6B"
    @State private var alertStyle: String = "gentle"
    @State private var isPRN: Bool = false
    @State private var minIntervalMinutes: Int = 0
    @State private var scheduleTimes: [(hour: Int, minute: Int)] = [(8, 0)]
    @State private var insight: MedicationInsight? = nil

    private var isEditing: Bool { medication != nil }
    private let intervalOptions = [0, 30, 60, 120, 180, 240, 360, 480]

    private let colorOptions = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"
    ]

    private let alertStyles = ["gentle", "urgent", "escalating"]

    init(medication: Medication? = nil) {
        self.medication = medication
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("medication") {
                    TextField("Name", text: $name)
                        .font(.system(.body, design: .monospaced))
                    TextField("Dosage (e.g. 500mg)", text: $dosage)
                        .font(.system(.body, design: .monospaced))
                }

                Section("type") {
                    Toggle("As needed (PRN)", isOn: $isPRN)
                        .font(.system(.body, design: .monospaced))

                    if isPRN {
                        Picker("Min interval", selection: $minIntervalMinutes) {
                            Text("none").tag(0)
                            ForEach(intervalOptions.filter { $0 > 0 }, id: \.self) { mins in
                                if mins < 60 {
                                    Text("\(mins)m").tag(mins)
                                } else {
                                    Text("\(mins / 60)h").tag(mins)
                                }
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                }

                Section("color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                                .accessibilityLabel(colorName(for: hex))
                                .accessibilityAddTraits(colorHex == hex ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("alert style") {
                    Picker("Style", selection: $alertStyle) {
                        ForEach(alertStyles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .font(.system(.body, design: .monospaced))
                }

                if !isPRN {
                    scheduleSection
                }
            }
            .navigationTitle(isEditing ? "edit med" : "add med")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .monospaced))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(.body, design: .monospaced))
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
        .preferredColorScheme(.dark)
    }

    private var scheduleSection: some View {
        Section("schedule") {
            ForEach(scheduleTimes.indices, id: \.self) { index in
                HStack {
                    let binding = Binding(
                        get: {
                            dateFrom(hour: scheduleTimes[index].hour, minute: scheduleTimes[index].minute)
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            scheduleTimes[index] = (components.hour ?? 8, components.minute ?? 0)
                        }
                    )
                    DatePicker("Time", selection: binding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .font(.system(.body, design: .monospaced))

                    Spacer()

                    if scheduleTimes.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                _ = scheduleTimes.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .slide.combined(with: .opacity),
                    removal: .opacity
                ))
            }

            if isEditing, let insight, let suggested = insight.suggestedTime {
                if let drift = insight.timeDriftMinutes, abs(drift) > 15 {
                    HStack {
                        Text("you usually take this at \(String(format: "%d:%02d", suggested.hour, suggested.minute))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("adjust") {
                            scheduleTimes = [(suggested.hour, suggested.minute)]
                        }
                        .font(.system(.caption2, design: .monospaced))
                    }
                }
                Text("consistency: \(insight.consistencyScore)%")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Button("+ add time") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    scheduleTimes.append((12, 0))
                }
            }
            .font(.system(.body, design: .monospaced))
        }
    }

    private func loadExisting() {
        guard let med = medication else { return }
        name = med.name
        dosage = med.dosage
        colorHex = med.colorHex
        alertStyle = med.alertStyle
        isPRN = med.isPRN
        minIntervalMinutes = med.minIntervalMinutes
        scheduleTimes = med.scheduleTimes.map { ($0.hour, $0.minute) }
        if scheduleTimes.isEmpty { scheduleTimes = [(8, 0)] }
        insight = AdherenceEngine.analyze(medication: med, recentEscalationCount: 0, now: Date())
    }

    private func save() {
        let med: Medication
        // Capture old notification IDs before modifying schedules
        var oldNotificationIds: [String] = []

        if let existing = medication {
            med = existing
            oldNotificationIds = med.scheduleTimes.map { time in
                "med-\(med.id.uuidString)-\(String(format: "%02d:%02d", time.hour, time.minute))"
            }
            med.name = name.trimmingCharacters(in: .whitespaces)
            med.dosage = dosage.trimmingCharacters(in: .whitespaces)
            med.colorHex = colorHex
            med.alertStyle = alertStyle
            med.isPRN = isPRN
            med.minIntervalMinutes = minIntervalMinutes
            for schedule in med.scheduleTimes {
                context.delete(schedule)
            }
            med.scheduleTimes = []
        } else {
            med = Medication(
                name: name.trimmingCharacters(in: .whitespaces),
                dosage: dosage.trimmingCharacters(in: .whitespaces),
                colorHex: colorHex,
                alertStyle: alertStyle
            )
            med.isPRN = isPRN
            med.minIntervalMinutes = minIntervalMinutes
            context.insert(med)
        }

        let notificationService = NotificationService()

        if isPRN {
            // Cancel any existing scheduled notifications for PRN meds
            for id in oldNotificationIds {
                notificationService.cancelNotification(id: id)
            }
        } else {
            for time in scheduleTimes {
                let schedule = ScheduleTime(hour: time.hour, minute: time.minute)
                med.scheduleTimes.append(schedule)
            }

            Task {
                _ = try? await notificationService.requestPermission()

                // Cancel OLD notification IDs
                for id in oldNotificationIds {
                    notificationService.cancelNotification(id: id)
                }

                try? await notificationService.scheduleAll(
                    medicationId: med.id.uuidString,
                    name: med.name,
                    dosage: med.dosage,
                    times: scheduleTimes,
                    alertStyle: alertStyle
                )
            }
        }

        dismiss()
    }

    private func colorName(for hex: String) -> String {
        switch hex {
        case "#FF6B6B": "Coral red"
        case "#4ECDC4": "Teal"
        case "#45B7D1": "Sky blue"
        case "#96CEB4": "Sage green"
        case "#FFEAA7": "Pale yellow"
        case "#DDA0DD": "Plum"
        case "#98D8C8": "Mint"
        case "#F7DC6F": "Gold"
        default: "Color"
        }
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
