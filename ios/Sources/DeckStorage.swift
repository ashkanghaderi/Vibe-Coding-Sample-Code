import Foundation

/// Reading and writing the deck list.
///
/// A protocol, so tests get a real implementation pointed at a temporary
/// directory rather than a fake. Persistence bugs live in the file handling -
/// partial writes, corrupt data, missing directories - and a mock has none of
/// that, so a mock proves nothing here.
protocol DeckStorage {
    func load() throws -> [Deck]
    func save(_ decks: [Deck]) throws
}

/// What went wrong, kept specific.
///
/// `LoadResult` exists because "no file" and "unreadable file" are the same
/// thing to `try?` and must never be the same thing to the app: the first is a
/// new install, the second is somebody's data.
enum StorageError: Error, Equatable {
    case unreadable(String)
}

struct FileDeckStorage: DeckStorage {
    let url: URL

    init(directory: URL) {
        self.url = directory.appendingPathComponent("decks.json")
    }

    func load() throws -> [Deck] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return DeckStore.sample                       // first run
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([Deck].self, from: data)
        } catch {
            // The file exists and does not parse. Somebody's decks are in
            // there, or were. Preserve it and say so; do NOT return [] and let
            // the next save overwrite it. See Chapter 9.
            try? preserveCorruptFile()
            throw StorageError.unreadable(String(describing: error))
        }
    }

    func save(_ decks: [Deck]) throws {
        let data = try JSONEncoder().encode(decks)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        // Atomic: a crash mid-write leaves the old file, not half of the new
        // one. Without this the failure is silent and only shows up next launch.
        try data.write(to: url, options: .atomic)
    }

    /// Move an unparseable file aside so the next save cannot destroy it.
    private func preserveCorruptFile() throws {
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("decks.corrupt-\(Int(Date().timeIntervalSince1970)).json")
        try FileManager.default.moveItem(at: url, to: backup)
    }
}
