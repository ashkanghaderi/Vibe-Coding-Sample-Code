import Foundation

/// One side-to-side flashcard.
///
/// Deliberately plain. Nothing here knows about scheduling, persistence, or
/// SwiftUI — those arrive in their own chapters, and keeping them out is what
/// lets a later change be reviewed as a small diff rather than a rewrite.
struct Card: Identifiable, Hashable {
    let id = UUID()
    var front: String
    var back: String
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
