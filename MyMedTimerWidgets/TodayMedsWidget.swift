import SwiftUI
import WidgetKit

struct TodayMedsEntry: TimelineEntry {
    let date: Date
    let remaining: [MedSnapshotEntry]
}

struct TodayMedsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayMedsEntry {
        TodayMedsEntry(date: .now, remaining: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayMedsEntry) -> Void) {
        completion(TodayMedsEntry(date: .now, remaining: MedSnapshot.load().remainingToday()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayMedsEntry>) -> Void) {
        let now = Date()
        let remaining = MedSnapshot.load().remainingToday(now: now)
        let entry = TodayMedsEntry(date: now, remaining: remaining)
        let refresh = remaining.first?.nextDose ?? Calendar.current.startOfDay(for: now.addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct TodayMedsWidget: Widget {
    let kind = "TodayMedsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayMedsProvider()) { entry in
            TodayMedsWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Today's Meds")
        .description("Remaining doses for today.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TodayMedsWidgetView: View {
    let entry: TodayMedsEntry

    var body: some View {
        if entry.remaining.isEmpty {
            VStack {
                Image(systemName: "checkmark.circle").font(.largeTitle)
                Text("All done today")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Remaining today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                ForEach(entry.remaining.prefix(5), id: \.id) { med in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: med.colorHex))
                            .frame(width: 8, height: 8)
                        Text(med.name)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Spacer()
                        Text(med.nextDose, format: .dateTime.hour().minute())
                            .monospacedDigit()
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                if entry.remaining.count > 5 {
                    Text("+\(entry.remaining.count - 5) more")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
            .padding(4)
        }
    }
}
