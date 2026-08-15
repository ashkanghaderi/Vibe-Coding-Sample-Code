import Foundation

/// One side-to-side flashcard.
///
/// Deliberately plain. Nothing here knows about scheduling, persistence, or
/// SwiftUI — those arrive in their own chapters, and keeping them out is what
/// lets a later change be reviewed as a small diff rather than a rewrite.
struct Card: Identifiable, Hashable, Codable {
    var id = UUID()
    var front: String
    var back: String

    init(id: UUID = UUID(), front: String, back: String) {
        self.id = id
        self.front = front
        self.back = back
    }

    /// Written by hand because the synthesized version does not use default
    /// values: `var id = UUID()` still makes `id` a required key. Cards that
    /// arrive from a generator have no id yet, and demanding one would make
    /// every reply fail to parse.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.front = try container.decode(String.self, forKey: .front)
        self.back = try container.decode(String.self, forKey: .back)
    }
}

extension Deck {
    /// The cards due in this deck.
    ///
    /// Sample data for now. Chapter 9 replaces the storage behind this without
    /// changing the property, which is the point of it being a property.
    var dueCards: [Card] {
        Deck.sampleCards[name] ?? []
    }

    static let sampleCards: [String: [Card]] = [
        "Spanish — Verbs": [
            Card(front: "to run", back: "correr"),
            Card(front: "to bring", back: "traer"),
            Card(front: "to leave", back: "salir"),
        ],
        "Kanji N5": [
            Card(front: "水", back: "water — みず"),
            Card(front: "火", back: "fire — ひ"),
        ],
    ]
}
