package com.ashkanghaderi.flashcards

/**
 * The same model as the iOS app, from the same specification.
 *
 * Kept deliberately parallel to Deck.swift and Card.swift so that Part III can
 * ask an honest question: which of the decisions in Part II were about the
 * practice, and which were about Swift?
 */
data class Card(val front: String, val back: String)

data class Deck(val name: String, val totalCount: Int) {
    /** Derived, never stored. Chapter 6, in Kotlin. */
    val dueCount: Int get() = sampleCards[name]?.size ?: 0

    val dueCards: List<Card> get() = sampleCards[name].orEmpty()

    companion object {
        val sampleCards: Map<String, List<Card>> = mapOf(
            "Spanish — Verbs" to listOf(
                Card("to run", "correr"),
                Card("to bring", "traer"),
                Card("to leave", "salir"),
            ),
            "Kanji N5" to listOf(
                Card("水", "water — みず"),
                Card("火", "fire — ひ"),
            ),
        )

        val sample: List<Deck> = listOf(
            Deck("Spanish — Verbs", 240),
            Deck("Spanish — Food", 86),
            Deck("Kanji N5", 103),
        )
    }
}
