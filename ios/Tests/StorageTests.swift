import Testing
import Foundation
@testable import Flashcards

@Suite("Storage")
struct StorageTests {

    /// A real directory per test. Persistence bugs are file bugs.
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("flashcards-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("A first run gets the sample decks, not an empty list")
    func firstRun() throws {
        let storage = FileDeckStorage(directory: try temporaryDirectory())
        #expect(try storage.load().count == DeckStore.sample.count)
    }

    @Test("Decks survive a round trip")
    func roundTrip() throws {
        let storage = FileDeckStorage(directory: try temporaryDirectory())
        let decks = [Deck(name: "Portuguese", totalCount: 12)]
        try storage.save(decks)
        let loaded = try storage.load()
        #expect(loaded == decks)
        #expect(loaded.first?.id == decks.first?.id)
    }

    @Test("An unreadable file is an error, not an empty list")
    func corruptFileThrows() throws {
        let directory = try temporaryDirectory()
        let storage = FileDeckStorage(directory: directory)
        try storage.save([Deck(name: "Portuguese", totalCount: 12)])
        try Data("{ this is not json".utf8).write(to: storage.url)

        #expect(throws: StorageError.self) {
            _ = try storage.load()
        }
    }

    @Test("An unreadable file is kept, not overwritten")
    func corruptFileIsPreserved() throws {
        let directory = try temporaryDirectory()
        let storage = FileDeckStorage(directory: directory)
        let original = Data("{ this is not json".utf8)
        try original.write(to: storage.url)

        _ = try? storage.load()

        let files = try FileManager.default
            .contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("decks.corrupt-") }
        #expect(files.count == 1, "the unreadable file should have been moved aside")
        let kept = try Data(contentsOf: directory.appendingPathComponent(files[0]))
        #expect(kept == original)
    }

    @Test("A store that failed to load refuses to save over it")
    func failedLoadDoesNotOverwrite() throws {
        let directory = try temporaryDirectory()
        let storage = FileDeckStorage(directory: directory)
        try Data("{ this is not json".utf8).write(to: storage.url)

        let store = DeckStore(storage: storage)
        #expect(store.loadError != nil)
        #expect(store.decks.isEmpty)

        store.add(named: "Portuguese")
        #expect(!FileManager.default.fileExists(atPath: storage.url.path),
                "a store in an error state must not write")
    }

    @Test("Adding a deck writes it to disk")
    func addPersists() throws {
        let directory = try temporaryDirectory()
        let storage = FileDeckStorage(directory: directory)
        let store = DeckStore(storage: storage)
        store.add(named: "Portuguese")

        let reloaded = DeckStore(storage: FileDeckStorage(directory: directory))
        #expect(reloaded.decks.last?.name == "Portuguese")
    }
}
