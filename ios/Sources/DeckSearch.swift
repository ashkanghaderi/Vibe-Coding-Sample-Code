import Foundation

/// Searching decks by name and by the text on their cards.
///
/// This is the obvious implementation, and it is the one that shipped.
///
/// An earlier version pre-lowercased every deck and card into one string per
/// deck, built once, on the theory that lowercasing per keystroke was the
/// expensive part. Measured on 2,000 decks and 40,000 cards it was 1.0-1.4x
/// faster per query and *slower* overall once the build cost was counted -
/// while debouncing the input, which needs no data structure at all, was up to
/// 7x. The index was deleted. See Chapter 13, and scripts/bench-search.swift.
enum DeckSearch {

    /// Decks matching the query, in their original order.
    ///
    /// An empty query returns everything, which is what a search field with
    /// nothing typed in it should show.
    static func results(for query: String, in decks: [Deck],
                        cards: (Deck) -> [Card]) -> [Deck] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return decks }
        return decks.filter { deck in
            if deck.name.lowercased().contains(needle) { return true }
            return cards(deck).contains {
                $0.front.lowercased().contains(needle)
                    || $0.back.lowercased().contains(needle)
            }
        }
    }
}
