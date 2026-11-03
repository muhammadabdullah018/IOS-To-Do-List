import Foundation

/// Storage boundary. The app uses `JSONFileStore`; tests use it with temp directories or
/// `InMemoryStore`. A SwiftData or CloudKit implementation can replace it without touching
/// the domain or views.
public protocol DataPersisting: AnyObject {
    func load() throws -> AppData?
    func save(_ data: AppData) throws
    func delete() throws
}

public enum PersistenceError: Error, LocalizedError, Equatable {
    case unsupportedSchema(Int)
    case corrupt(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let v): return "This data was created by a newer version of Skyday (schema \(v))."
        case .corrupt(let detail): return "Saved data could not be read: \(detail)"
        }
    }
}

/// Offline-first single-document store.
///
/// - Writes are atomic (write to temp + rename), so a crash mid-save never leaves a torn file.
/// - A file that fails to decode is never overwritten: it is moved aside to
///   `skyday-unreadable-<timestamp>.json` and reported, so nothing is silently lost.
/// - `schemaVersion` gates migrations; unknown optional fields decode with defaults.
public final class JSONFileStore: DataPersisting {
    public let fileURL: URL
    private let fileManager: FileManager

    public init(directory: URL, fileName: String = "skyday.json", fileManager: FileManager = .default) {
        self.fileURL = directory.appendingPathComponent(fileName)
        self.fileManager = fileManager
    }

    public static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601WithFractionalSecondsFallback
        return e
    }

    public static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601WithFractionalSecondsFallback
        return d
    }

    public func load() throws -> AppData? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let raw = try Data(contentsOf: fileURL)
        do {
            return try JSONFileStore.decode(raw)
        } catch let error as PersistenceError {
            if case .unsupportedSchema = error { throw error }
            try quarantine()
            throw error
        } catch {
            try quarantine()
            throw PersistenceError.corrupt(String(describing: error))
        }
    }

    public static func decode(_ raw: Data) throws -> AppData {
        struct Header: Decodable { var schemaVersion: Int? }
        let header = try decoder().decode(Header.self, from: raw)
        let version = header.schemaVersion ?? 1
        guard version <= AppData.currentSchemaVersion else { throw PersistenceError.unsupportedSchema(version) }
        // Future: switch on `version` and migrate older documents here before decoding.
        var data = try decoder().decode(AppData.self, from: raw)
        data.schemaVersion = AppData.currentSchemaVersion
        if !data.lists.contains(where: \.isInbox) {
            data.lists.insert(TaskList(name: "Inbox", icon: "tray.fill", color: .sky, sortOrder: -1, isInbox: true, createdAt: Date()), at: 0)
        }
        // Repair orphaned tasks (list missing) by moving them to Inbox.
        let listIDs = Set(data.lists.map(\.id))
        let inboxID = data.inbox.id
        for i in data.tasks.indices where !listIDs.contains(data.tasks[i].listID) {
            data.tasks[i].listID = inboxID
        }
        return data
    }

    public func save(_ data: AppData) throws {
        try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoded = try JSONFileStore.encoder().encode(data)
        #if os(iOS)
        // Readable after first unlock so reminders, widget refresh and notification actions work while locked.
        try encoded.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try encoded.write(to: fileURL, options: [.atomic])
        #endif
    }

    public func delete() throws {
        if fileManager.fileExists(atPath: fileURL.path) { try fileManager.removeItem(at: fileURL) }
    }

    /// Moves an unreadable file aside so the next save cannot destroy it.
    @discardableResult
    public func quarantine() throws -> URL? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let stamp = Int(Date().timeIntervalSince1970)
        let target = fileURL.deletingLastPathComponent().appendingPathComponent("skyday-unreadable-\(stamp).json")
        try? fileManager.removeItem(at: target)
        try fileManager.moveItem(at: fileURL, to: target)
        return target
    }
}

public final class InMemoryStore: DataPersisting {
    public private(set) var stored: AppData?
    public private(set) var saveCount = 0
    public var failNextSave = false

    public init(_ initial: AppData? = nil) { stored = initial }

    public func load() throws -> AppData? { stored }

    public func save(_ data: AppData) throws {
        if failNextSave {
            failNextSave = false
            throw PersistenceError.corrupt("simulated failure")
        }
        stored = data
        saveCount += 1
    }

    public func delete() throws { stored = nil }
}

extension JSONEncoder.DateEncodingStrategy {
    /// ISO-8601 with fractional seconds, readable in exported backups.
    static var iso8601WithFractionalSecondsFallback: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(SkydayDateFormat.string(from: date))
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithFractionalSecondsFallback: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self), let d = SkydayDateFormat.date(from: s) { return d }
            if let t = try? c.decode(Double.self) { return Date(timeIntervalSinceReferenceDate: t) }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unrecognised date")
        }
    }
}

enum SkydayDateFormat {
    // Formatter creation is expensive (it was ~85% of save time with 600 tasks), so reuse
    // instances. ISO8601DateFormatter is safe to use concurrently once configured; the lock
    // keeps this correct on every platform regardless.
    private static let lock = NSLock()
    private static let fractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let whole: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func string(from date: Date) -> String {
        lock.lock(); defer { lock.unlock() }
        return fractional.string(from: date)
    }

    static func date(from string: String) -> Date? {
        lock.lock(); defer { lock.unlock() }
        return fractional.date(from: string) ?? whole.date(from: string)
    }
}
