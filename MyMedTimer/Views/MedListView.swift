import SwiftUI
import SwiftData

struct MedListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.name)
    private var medications: [Medication]

    @State private var showingAddSheet = false
    @State private var editingMedication: Medication?
    @State private var loggingMedication: Medication?
    @State private var deletingMedication: Medication?
    @State private var now = Date()
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var insights: [UUID: MedicationInsight] = [:]
    @State private var insightTickCounter = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sortedMeds: [Medication] {
        MedicationService.sortedByNextDose(Array(medications), after: now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if medications.isEmpty {
                    emptyState
                        .transition(.opacity)
                } else {
                    medList
                        .transition(.opacity)
                }

                if showToast, let message = toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 60)
                            .transition(.opacity)
                    }
                    .allowsHitTesting(false)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { showingAddSheet = true } label: {
                        Label("Add Med", systemImage: "plus")
                            .font(.system(.body, design: .monospaced))
                    }
                    Spacer()
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("History", systemImage: "list.bullet")
                            .font(.system(.body, design: .monospaced))
                    }
                    Spacer()
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditMedView()
            }
            .sheet(item: $editingMedication) { med in
                AddEditMedView(medication: med)
            }
            .confirmationDialog(
                confirmationTitle,
                isPresented: Binding(
                    get: { loggingMedication != nil },
                    set: { if !$0 { loggingMedication = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let med = loggingMedication {
                    if med.isPRN {
                        let canTake = MedicationService.canTakePRN(med, now: now)
                        Button(canTake ? "Take now" : "Take anyway") {
                            logDose(status: "taken")
                        }
                    } else {
                        Button("Taken") {
                            logDose(status: "taken")
                        }
                        Button("Skipped") {
                            logDose(status: "skipped")
                        }
                        Button("Snooze 10min") {
                            logDose(status: "snoozed")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    loggingMedication = nil
                }
            }
            .alert(
                "Delete \(deletingMedication?.name ?? "")?",
                isPresented: Binding(
                    get: { deletingMedication != nil },
                    set: { if !$0 { deletingMedication = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let med = deletingMedication {
                        // Cancel notifications before deleting
                        let service = NotificationService()
                        for time in med.scheduleTimes {
                            let id = "med-\(med.id.uuidString)-\(String(format: "%02d:%02d", time.hour, time.minute))"
                            service.cancelNotification(id: id)
                            service.cancelNags(baseId: id)
                        }
                        context.delete(med)
                    }
                    deletingMedication = nil
                }
                Button("Cancel", role: .cancel) {
                    deletingMedication = nil
                }
            } message: {
                Text("This will remove all schedules and dose history for this medication.")
            }
            .onReceive(timer) { date in
                now = date
                insightTickCounter += 1
                if insightTickCounter >= 60 {
                    insightTickCounter = 0
                    refreshInsights()
                }
            }
            .onAppear { refreshInsights() }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("no meds")
                .font(.system(.title2, design: .monospaced))
                .foregroundStyle(.secondary)
            Button("+ add medication") { showingAddSheet = true }
                .font(.system(.body, design: .monospaced))
        }
    }

    private var confirmationTitle: String {
        guard let med = loggingMedication else { return "" }
        if med.isPRN, !MedicationService.canTakePRN(med, now: now) {
            let mins = MedicationService.minutesUntilCanTake(med, now: now)
            return "\(med.name) — wait \(mins)m before next dose"
        }
        return med.name
    }

    private func prnWarning(for med: Medication) -> String? {
        guard med.isPRN, !MedicationService.canTakePRN(med, now: now) else { return nil }
        let mins = MedicationService.minutesUntilCanTake(med, now: now)
        return "wait \(mins)m"
    }

    private func logDose(status: String) {
        guard let med = loggingMedication else { return }
        let scheduledTime = MedicationService.nextDoseTime(for: med, after: now) ?? now
        DoseService.logDose(for: med, scheduledTime: scheduledTime, status: status, in: context)

        switch status {
        case "taken": HapticService.play(.success)
        case "skipped": HapticService.play(.notification)
        case "snoozed": HapticService.play(.notification)
        default: break
        }

        // Cancel nags for this med's current notification
        if !med.isPRN {
            let service = NotificationService()
            for time in med.scheduleTimes {
                let id = "med-\(med.id.uuidString)-\(String(format: "%02d:%02d", time.hour, time.minute))"
                service.cancelNags(baseId: id)
            }
        }

        let toastLabel: String
        switch status {
        case "taken": toastLabel = "\(med.name) — taken"
        case "skipped": toastLabel = "\(med.name) — skipped"
        case "snoozed": toastLabel = "\(med.name) — snoozed 10m"
        default: toastLabel = med.name
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            loggingMedication = nil
        }

        toastMessage = toastLabel
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }

    private func refreshInsights() {
        let results = AdherenceEngine.analyzeAll(medications: Array(medications), now: now)
        var map: [UUID: MedicationInsight] = [:]
        for insight in results {
            map[insight.medicationId] = insight
        }
        insights = map
    }

    private var medList: some View {
        List {
            ForEach(sortedMeds) { med in
                MedRowView(
                    name: med.name,
                    dosage: med.dosage,
                    colorHex: med.colorHex,
                    isPRN: med.isPRN,
                    nextDoseTime: med.isPRN ? nil : MedicationService.nextDoseTime(for: med, after: now),
                    lastTakenTime: med.isPRN ? MedicationService.lastTakenTime(for: med) : nil,
                    prnWarning: prnWarning(for: med),
                    now: now,
                    riskLevel: insights[med.id]?.riskLevel,
                    onTap: {
                        loggingMedication = med
                    }
                )
                .listRowBackground(Color.black)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deletingMedication = med
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        editingMedication = med
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.gray)
                }
                .contextMenu {
                    Button {
                        editingMedication = med
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deletingMedication = med
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .onLongPressGesture {
                    editingMedication = med
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .animation(.easeInOut(duration: 0.3), value: sortedMeds.map(\.id))
    }
}
