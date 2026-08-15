import Foundation
import Observation

/// The decks the app knows about.
///
/// The list lives here rather than in `@State` on the view, for the reason
/// Chapter 5 gives: a rule about *what may be added* is logic, and logic on a
/// view can only be checked by tapping. Here it is seven tests.
@Observable
final class DeckStore {
    private(set) var decks: [Deck]

    /// Set when loading failed. The app shows it; it does not swallow it.
    private(set) var loadError: String?

    private let storage: DeckStorage?

    init(decks: [Deck] = DeckStore.sample) {
        self.decks = decks
        self.storage = nil
    }

    /// Loads from storage, keeping the failure if there is one.
    ///
    /// On an unreadable file this deliberately does *not* fall back to the
    /// sample decks. Starting fresh looks like recovery and is data loss with a
    /// friendly face - the next save would overwrite what could not be read.
    init(storage: DeckStorage) {
        self.storage = storage
        do {
            self.decks = try storage.load()
        } catch {
            self.decks = []
            self.loadError = String(describing: error)
        }
    }

    static let sample: [Deck] = [
        Deck(name: "Spanish — Verbs", totalCount: 240),
        Deck(name: "Spanish — Food", totalCount: 86),
        Deck(name: "Kanji N5", totalCount: 103),
    ]

    private func persist() {
        guard let storage, loadError == nil else { return }
        try? storage.save(decks)
    }

    /// Whether a proposed name can be added.
    ///
    /// Trimmed, non-empty, and not already taken. The comparison is
    /// case-insensitive because "kanji n5" and "Kanji N5" are the same deck to
    /// everyone except a string.
    func canAdd(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !decks.contains { $0.name.lowercased() == trimmed.lowercased() }
    }

    /// Adds a deck, if the name is acceptable.
    ///
    /// - Returns: whether it was added, so a caller can tell the difference
    ///   between "done" and "silently ignored".
    @discardableResult
    func add(named name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canAdd(trimmed) else { return false }
        decks.append(Deck(name: trimmed, totalCount: 0))
        persist()
        return true
    }
}
