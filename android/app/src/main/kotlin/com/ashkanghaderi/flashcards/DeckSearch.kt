package com.ashkanghaderi.flashcards

/**
 * Searching decks by name and card text.
 *
 * The obvious implementation, for the reason Chapter 13 measured on the iOS
 * side: the index that replaced it was slower once its build cost was counted,
 * and debouncing beat both. The port keeps the conclusion, not just the code.
 */
object DeckSearch {
    fun results(query: String, decks: List<Deck>, cards: (Deck) -> List<Card>): List<Deck> {
        val needle = query.trim().lowercase()
        if (needle.isEmpty()) return decks
        return decks.filter { deck ->
            deck.name.lowercase().contains(needle) || cards(deck).any {
                it.front.lowercase().contains(needle) || it.back.lowercase().contains(needle)
            }
        }
    }
}
