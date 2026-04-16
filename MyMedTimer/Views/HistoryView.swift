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
                    Section {
                        AdherenceHeatmap(logs: allLogs)
                            .listRowBackground(Color.clear)
                    }

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

// MARK: - Adherence Heatmap

private struct AdherenceHeatmap: View {
    let logs: [DoseLog]
    private let columns = 7
    private let weeks = 8

    private var dayData: [Date: DayStatus] {
        let calendar = Calendar.current
        var result: [Date: DayStatus] = [:]

        for log in logs {
            let day = calendar.startOfDay(for: log.scheduledTime)
            let existing = result[day] ?? .none

            switch log.status {
            case "taken":
                if existing != .mixed && existing != .missed {
                    result[day] = .taken
                } else if existing == .missed {
                    result[day] = .mixed
                }
            case "skipped":
                if existing == .taken {
                    result[day] = .mixed
                } else {
                    result[day] = .missed
                }
            case "snoozed":
                if existing == .none {
                    result[day] = .snoozed
                }
            default:
                break
            }
        }
        return result
    }

    private var days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * columns
        return (0..<totalDays).compactMap { offset in
            calendar.date(byAdding: .day, value: -(totalDays - 1 - offset), to: today)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("last \(weeks) weeks")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: columns), spacing: 3) {
                ForEach(days, id: \.self) { day in
                    let status = dayData[day] ?? .none
                    RoundedRectangle(cornerRadius: 2)
                        .fill(status.color)
                        .frame(height: 14)
                }
            }

            HStack(spacing: 8) {
                legendDot(color: .green.opacity(0.8), label: "taken")
                legendDot(color: .red.opacity(0.7), label: "missed")
                legendDot(color: .yellow.opacity(0.6), label: "late")
                legendDot(color: Color.white.opacity(0.08), label: "none")
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}

private enum DayStatus {
    case none, taken, missed, snoozed, mixed

    var color: Color {
        switch self {
        case .none: Color.white.opacity(0.08)
        case .taken: .green.opacity(0.8)
        case .missed: .red.opacity(0.7)
        case .snoozed: .yellow.opacity(0.6)
        case .mixed: .orange.opacity(0.7)
        }
    }
}
