import SwiftUI

struct MedRowView: View {
    let name: String
    let dosage: String
    let colorHex: String
    let isPRN: Bool
    let nextDoseTime: Date?
    let lastTakenTime: Date?
    let prnWarning: String?
    let now: Date
    let riskLevel: RiskLevel?
    let onTap: () -> Void

    init(
        name: String,
        dosage: String,
        colorHex: String,
        isPRN: Bool,
        nextDoseTime: Date?,
        lastTakenTime: Date?,
        prnWarning: String?,
        now: Date,
        riskLevel: RiskLevel? = nil,
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.dosage = dosage
        self.colorHex = colorHex
        self.isPRN = isPRN
        self.nextDoseTime = nextDoseTime
        self.lastTakenTime = lastTakenTime
        self.prnWarning = prnWarning
        self.now = now
        self.riskLevel = riskLevel
        self.onTap = onTap
    }

    private var accessibilityDescription: String {
        var parts = [name]
        if !dosage.isEmpty { parts.append(dosage) }

        if isPRN {
            parts.append("as needed")
            if let warning = prnWarning {
                parts.append(warning)
            } else if let last = lastTakenTime {
                let elapsed = now.timeIntervalSince(last)
                parts.append("last taken \(TimeFormatting.countdown(elapsed)) ago")
            } else {
                parts.append("not taken")
            }
        } else if let nextDose = nextDoseTime {
            let interval = nextDose.timeIntervalSince(now)
            if interval < 0 {
                parts.append("overdue")
            } else {
                parts.append("next dose in \(TimeFormatting.countdown(interval))")
            }
        }

        return parts.joined(separator: ", ")
    }

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

            if isPRN {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("PRN")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundStyle(.secondary)
                    if let warning = prnWarning {
                        Text(warning)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.orange)
                    } else if let last = lastTakenTime {
                        let elapsed = now.timeIntervalSince(last)
                        Text(TimeFormatting.countdown(elapsed) + " ago")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("not taken")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let nextDose = nextDoseTime {
                let interval = nextDose.timeIntervalSince(now)
                Text(TimeFormatting.countdown(interval))
                    .font(.system(.title3, design: .monospaced, weight: .bold))
                    .foregroundStyle(interval < 300 ? .red : .primary)
                    .animation(.easeInOut(duration: 0.5), value: interval < 300)
            } else {
                Text("--")
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if let risk = riskLevel, risk >= .medium {
                Circle()
                    .fill(risk == .high ? Color.red : Color.yellow)
                    .frame(width: 6, height: 6)
                    .accessibilityLabel(risk == .high ? "high risk" : "medium risk")
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(accessibilityDescription)
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
