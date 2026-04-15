import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DoseLog.scheduledTime, order: .reverse) private var allLogs: [DoseLog]

    private var groupedByDay: [(String, [DoseLog])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: allLogs) { log in
            formatter.string(from: log.scheduledTime)
        }

        return grouped.sorted { a, b in
            guard let aDate = allLogs.first(where: { formatter.string(from: $0.scheduledTime) == a.key })?.scheduledTime,
                  let bDate = allLogs.first(where: { formatter.string(from: $0.scheduledTime) == b.key })?.scheduledTime
            else { return false }
            return aDate > bDate
        }
    }

    var body: some View {
        Group {
            if allLogs.isEmpty {
                VStack {
                    Spacer()
                    Text("no dose history yet")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(groupedByDay, id: \.0) { day, logs in
                        Section(day) {
                            ForEach(logs) { log in
                                HStack {
                                    statusIcon(log.status)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.medication?.name ?? "Unknown")
                                            .font(.system(.body, design: .monospaced))
                                        Text(log.medication?.dosage ?? "")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(timeString(log.actualTime ?? log.scheduledTime))
                                            .font(.system(.caption, design: .monospaced))
                                        Text(log.status)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(statusColor(log.status))
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("history")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func statusIcon(_ status: String) -> some View {
        let (icon, color): (String, Color) = switch status {
        case "taken": ("checkmark.circle.fill", .green)
        case "skipped": ("xmark.circle.fill", .red)
        case "snoozed": ("clock.fill", .yellow)
        default: ("questionmark.circle", .gray)
        }
        return Image(systemName: icon)
            .foregroundStyle(color)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "taken": .green
        case "skipped": .red
        case "snoozed": .yellow
        default: .gray
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
