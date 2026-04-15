import SwiftUI
import SwiftData

struct MedListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.name)
    private var medications: [Medication]

    @State private var showingAddSheet = false
    @State private var editingMedication: Medication?
    @State private var loggingMedication: Medication?
    @State private var now = Date()

    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var sortedMeds: [Medication] {
        MedicationService.sortedByNextDose(Array(medications), after: now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if medications.isEmpty {
                    emptyState
                } else {
                    medList
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
            .onReceive(timer) { now = $0 }
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
        loggingMedication = nil
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
                    onTap: {
                        loggingMedication = med
                    }
                )
                .listRowBackground(Color.black)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        context.delete(med)
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
    }
}
