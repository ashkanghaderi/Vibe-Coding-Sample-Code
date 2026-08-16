package com.ashkanghaderi.flashcards

/**
 * The decks the app knows about, and the rule about what may be added.
 *
 * Port of DeckStore.swift. The rule lives here rather than in the Activity for
 * exactly the reason Chapter 8 gives - on a view it could only be checked by
 * typing into an emulator.
 */
class DeckStore(
    decks: List<Deck> = sample,
    private val storage: DeckStorage? = null,
) {
    var decks: List<Deck> = decks
        private set

    var loadError: String? = null
        private set

    companion object {
        val sample: List<Deck> = Deck.sample

        /** Loads from storage, keeping the failure rather than hiding it. */
        fun loading(storage: DeckStorage): DeckStore {
            val store = DeckStore(emptyList(), storage)
            try {
                store.decks = storage.load()
            } catch (error: StorageException) {
                store.loadError = error.message
            }
            return store
        }
    }

    fun canAdd(name: String): Boolean {
        val trimmed = name.trim()
        if (trimmed.isEmpty()) return false
        return decks.none { it.name.equals(trimmed, ignoreCase = true) }
    }

    fun add(name: String): Boolean {
        val trimmed = name.trim()
        if (!canAdd(trimmed)) return false
        decks = decks + Deck(trimmed, 0)
        persist()
        return true
    }

    private fun persist() {
        val storage = storage ?: return
        if (loadError != null) return          // Chapter 9: never write over it
        runCatching { storage.save(decks) }
    }
}
