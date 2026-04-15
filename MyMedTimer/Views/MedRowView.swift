import SwiftUI

struct MedRowView: View {
    let name: String
    let dosage: String
    let colorHex: String
    let nextDoseTime: Date?
    let onTap: () -> Void

    @State private var now = Date()
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: colorHex))
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(dosage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let nextDose = nextDoseTime {
                let interval = nextDose.timeIntervalSince(now)
                Text(TimeFormatting.countdown(interval))
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(interval < 300 ? .red : .primary)
            } else {
                Text("--")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onReceive(timer) { now = $0 }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
