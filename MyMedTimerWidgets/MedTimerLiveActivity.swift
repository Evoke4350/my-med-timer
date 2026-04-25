import ActivityKit
import SwiftUI
import WidgetKit

struct MedTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MedTimerActivityAttributes.self) { context in
            LockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(Color(hex: context.state.colorHex))
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.fireDate, countsDown: true)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.medName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "pills.fill")
                    .foregroundStyle(Color(hex: context.state.colorHex))
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.fireDate, countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 50)
            } minimal: {
                Image(systemName: "pills.fill")
                    .foregroundStyle(Color(hex: context.state.colorHex))
            }
        }
    }
}

private struct LockScreenLiveActivityView: View {
    let state: MedTimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.title)
                .foregroundStyle(Color(hex: state.colorHex))
            VStack(alignment: .leading, spacing: 2) {
                Text(state.medName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(state.dosage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Text(timerInterval: Date()...state.fireDate, countsDown: true)
                .font(.title2.monospacedDigit())
                .foregroundStyle(.white)
                .frame(maxWidth: 100, alignment: .trailing)
        }
        .padding()
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
