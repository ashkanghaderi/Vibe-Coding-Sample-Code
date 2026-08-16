package com.ashkanghaderi.flashcards

import org.junit.Assert.*
import org.junit.Test
import java.io.File
import java.nio.file.Files

/**
 * The same assertions as the iOS suite, in JUnit rather than Swift Testing.
 *
 * Chapter 19 compares them. The interesting difference is not the syntax - it
 * is that JUnit 4 has no parameterised cases without a runner, and two of this
 * book's eighteen recorded failures were caught by parameterised arguments.
 */
class SchedulerTest {

    @Test fun `a new card answered correctly comes back tomorrow`() {
        val next = Scheduler.next(Scheduler.State(), Scheduler.Grade.GOOD)
        assertEquals(1, next.interval)
        assertEquals(1, next.streak)
    }

    @Test fun `the second correct answer jumps to six days`() {
        var state = Scheduler.next(Scheduler.State(), Scheduler.Grade.GOOD)
        state = Scheduler.next(state, Scheduler.Grade.GOOD)
        assertEquals(6, state.interval)
    }

    @Test fun `after that intervals multiply by ease`() {
        val state = Scheduler.next(
            Scheduler.State(interval = 6, ease = 2.5, streak = 2), Scheduler.Grade.GOOD)
        assertEquals(15, state.interval)
    }

    @Test fun `a wrong answer resets the streak and the interval`() {
        val next = Scheduler.next(
            Scheduler.State(interval = 40, ease = 2.5, streak = 6), Scheduler.Grade.AGAIN)
        assertEquals(1, next.interval)
        assertEquals(0, next.streak)
    }

    @Test fun `ease never drops below the floor from any starting point`() {
        // No @Test arguments in JUnit 4 without a runner, so the loop is
        // explicit. It is the same four cases the Swift suite declares.
        for (start in listOf(1.3, 1.4, 2.5, 3.0)) {
            val state = Scheduler.next(Scheduler.State(ease = start), Scheduler.Grade.AGAIN)
            assertTrue("ease $start fell below the floor", state.ease >= Scheduler.MINIMUM_EASE)
        }
    }
}

class DeckStoreTest {

    @Test fun `a deck's badge matches the cards it will serve`() {
        for (deck in Deck.sample) assertEquals(deck.dueCards.size, deck.dueCount)
    }

    @Test fun `blank and duplicate names are refused`() {
        val store = DeckStore()
        for (blank in listOf("", " ", "\n", "\t  ")) assertFalse(store.canAdd(blank))
        for (dupe in listOf("Kanji N5", "kanji n5", "KANJI N5", "  Kanji N5  ")) {
            assertFalse(store.canAdd(dupe))
        }
    }

    @Test fun `whitespace is trimmed, not preserved`() {
        val store = DeckStore()
        store.add("   Portuguese   ")
        assertEquals("Portuguese", store.decks.last().name)
    }

    @Test fun `search matches names and card text`() {
        val cards = { deck: Deck -> deck.dueCards }
        assertEquals(listOf("Kanji N5"),
            DeckSearch.results("kanji", Deck.sample, cards).map { it.name })
        assertEquals(listOf("Spanish — Verbs"),
            DeckSearch.results("correr", Deck.sample, cards).map { it.name })
        assertEquals(Deck.sample.size, DeckSearch.results("  ", Deck.sample, cards).size)
    }
}

class StorageTest {

    private fun directory(): File = Files.createTempDirectory("flashcards").toFile()

    @Test fun `a first run gets the sample decks`() {
        assertEquals(Deck.sample.size, FileDeckStorage(directory()).load().size)
    }

    @Test fun `decks survive a round trip`() {
        val storage = FileDeckStorage(directory())
        val decks = listOf(Deck("Portuguese", 12), Deck("""Quotes " and \ slashes""", 3))
        storage.save(decks)
        assertEquals(decks, storage.load())
    }

    @Test fun `an unreadable file is an error, not an empty list`() {
        val storage = FileDeckStorage(directory())
        storage.file.parentFile.mkdirs()
        storage.file.writeText("{ this is not json")
        try {
            storage.load(); fail("expected a StorageException")
        } catch (expected: StorageException) { }
    }

    @Test fun `an unreadable file is kept, not overwritten`() {
        val dir = directory()
        val storage = FileDeckStorage(dir)
        storage.file.parentFile.mkdirs()
        storage.file.writeText("{ this is not json")
        runCatching { storage.load() }
        assertEquals(1, dir.listFiles()!!.count { it.name.startsWith("decks.corrupt-") })
    }

    @Test fun `a store that failed to load refuses to save over it`() {
        val dir = directory()
        val storage = FileDeckStorage(dir)
        storage.file.parentFile.mkdirs()
        storage.file.writeText("{ this is not json")
        val store = DeckStore.loading(storage)
        assertNotNull(store.loadError)
        store.add("Portuguese")
        assertFalse("a store in an error state must not write", storage.file.exists())
    }
}
