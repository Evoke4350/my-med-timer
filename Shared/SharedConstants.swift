import Foundation

enum SharedConstants {
    static let appGroup = "group.com.nateb.mymedtimer"
    static let snapshotFilename = "med_snapshot.json"

    static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(snapshotFilename)
    }
}
