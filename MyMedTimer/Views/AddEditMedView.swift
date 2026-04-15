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
    @State private var scheduleTimes: [(hour: Int, minute: Int)] = [(8, 0)]

    private var isEditing: Bool { medication != nil }

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

                Section("color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                )
                                .onTapGesture { colorHex = hex }
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
                                    scheduleTimes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    Button("+ add time") {
                        scheduleTimes.append((12, 0))
                    }
                    .font(.system(.body, design: .monospaced))
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

    private func loadExisting() {
        guard let med = medication else { return }
        name = med.name
        dosage = med.dosage
        colorHex = med.colorHex
        alertStyle = med.alertStyle
        scheduleTimes = med.scheduleTimes.map { ($0.hour, $0.minute) }
        if scheduleTimes.isEmpty { scheduleTimes = [(8, 0)] }
    }

    private func save() {
        let med: Medication
        if let existing = medication {
            med = existing
            med.name = name.trimmingCharacters(in: .whitespaces)
            med.dosage = dosage.trimmingCharacters(in: .whitespaces)
            med.colorHex = colorHex
            med.alertStyle = alertStyle
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
            context.insert(med)
        }

        for time in scheduleTimes {
            let schedule = ScheduleTime(hour: time.hour, minute: time.minute)
            med.scheduleTimes.append(schedule)
        }

        Task {
            let notificationService = NotificationService()
            _ = try? await notificationService.requestPermission()

            for time in med.scheduleTimes {
                let id = "med-\(med.id.uuidString)-\(String(format: "%02d:%02d", time.hour, time.minute))"
                notificationService.cancelNotification(id: id)
            }

            try? await notificationService.scheduleAll(
                medicationId: med.id.uuidString,
                name: med.name,
                dosage: med.dosage,
                times: scheduleTimes
            )
        }

        dismiss()
    }

    private func dateFrom(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
