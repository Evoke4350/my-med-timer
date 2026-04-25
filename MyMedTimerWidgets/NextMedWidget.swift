import SwiftUI
import WidgetKit

struct NextMedEntry: TimelineEntry {
    let date: Date
    let entry: MedSnapshotEntry?
}

struct NextMedProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextMedEntry {
        NextMedEntry(date: .now, entry: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextMedEntry) -> Void) {
        completion(NextMedEntry(date: .now, entry: MedSnapshot.load().nextUpcoming))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextMedEntry>) -> Void) {
        let snap = MedSnapshot.load()
        let next = snap.nextUpcoming
        let entry = NextMedEntry(date: .now, entry: next)
        let refresh = next?.nextDose ?? Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct NextMedWidget: Widget {
    let kind = "NextMedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextMedProvider()) { entry in
            NextMedWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Next Dose")
        .description("Shows your next medication dose with live countdown.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
            .systemSmall,
        ])
    }
}

struct NextMedWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NextMedEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryInline: inline
        case .accessoryRectangular: rectangular
        case .systemSmall: small
        default: rectangular
        }
    }

    @ViewBuilder
    private var circular: some View {
        if let med = entry.entry {
            VStack(spacing: 0) {
                Image(systemName: "pills.fill").font(.caption2)
                Text(med.nextDose, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
        } else {
            Image(systemName: "pills").font(.title3)
        }
    }

    @ViewBuilder
    private var inline: some View {
        if let med = entry.entry {
            Text("\(med.name) in \(med.nextDose, style: .timer)")
        } else {
            Text("No meds scheduled")
        }
    }

    @ViewBuilder
    private var rectangular: some View {
        if let med = entry.entry {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "pills.fill")
                    Text(med.name).font(.headline).lineLimit(1)
                }
                Text(med.dosage).font(.caption2).lineLimit(1)
                Text(med.nextDose, style: .timer)
                    .monospacedDigit()
                    .font(.caption.bold())
            }
        } else {
            Text("No meds scheduled")
                .font(.caption)
        }
    }

    @ViewBuilder
    private var small: some View {
        if let med = entry.entry {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "pills.fill")
                    .foregroundStyle(Color(hex: med.colorHex))
                    .font(.title)
                Spacer()
                Text(med.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text(med.dosage)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                Text(med.nextDose, style: .timer)
                    .monospacedDigit()
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack {
                Image(systemName: "pills").font(.title)
                Text("No meds")
            }
            .foregroundStyle(.white)
        }
    }
}
