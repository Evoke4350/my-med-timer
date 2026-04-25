import Foundation

struct MedSnapshotEntry: Codable, Hashable {
    let id: String
    let name: String
    let dosage: String
    let colorHex: String
    let nextDose: Date
}

struct MedSnapshot: Codable {
    let generatedAt: Date
    let entries: [MedSnapshotEntry]

    static let empty = MedSnapshot(generatedAt: .distantPast, entries: [])

    var nextUpcoming: MedSnapshotEntry? {
        entries.min(by: { $0.nextDose < $1.nextDose })
    }

    func remainingToday(now: Date = Date()) -> [MedSnapshotEntry] {
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        return entries
            .filter { $0.nextDose >= now && $0.nextDose <= endOfDay }
            .sorted { $0.nextDose < $1.nextDose }
    }

    static func load() -> MedSnapshot {
        guard let url = SharedConstants.snapshotURL,
              let data = try? Data(contentsOf: url),
              let snap = try? JSONDecoder.shared.decode(MedSnapshot.self, from: data)
        else { return .empty }
        return snap
    }

    func save() throws {
        guard let url = SharedConstants.snapshotURL else { return }
        let data = try JSONEncoder.shared.encode(self)
        try data.write(to: url, options: .atomic)
    }
}

extension JSONEncoder {
    static let shared: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}

extension JSONDecoder {
    static let shared: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
