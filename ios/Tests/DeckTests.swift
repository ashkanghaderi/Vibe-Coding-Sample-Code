import Testing
@testable import Flashcards

@Suite("Deck")
struct DeckTests {

    /// The badge on the deck list and the cards the review screen serves must
    /// come from the same place. They did not, which is Chapter 6.
    @Test("A deck's due badge matches the cards it will actually serve")
    func badgeMatchesCards() {
        for deck in DeckStore.sample {
            #expect(
                deck.dueCount == deck.dueCards.count,
                "\(deck.name) shows \(deck.dueCount) due but serves \(deck.dueCards.count)"
            )
        }
    }

    @Test("A deck never claims more due cards than it has")
    func dueNeverExceedsTotal() {
        for deck in DeckStore.sample {
            #expect(deck.dueCount <= deck.totalCount)
        }
    }
}

@Suite("DeckStore")
struct DeckStoreTests {

    @Test("A new deck is added")
    func addsADeck() {
        let store = DeckStore()
        #expect(store.add(named: "Portuguese"))
        #expect(store.decks.count == DeckStore.sample.count + 1)
        #expect(store.decks.last?.name == "Portuguese")
    }

    @Test("A new deck starts with nothing due")
    func newDeckIsEmpty() {
        let store = DeckStore()
        store.add(named: "Portuguese")
        let deck = store.decks.last
        #expect(deck?.dueCount == 0)
        #expect(deck?.totalCount == 0)
    }

    @Test("Whitespace is trimmed, not preserved")
    func trimsWhitespace() {
        let store = DeckStore()
        store.add(named: "   Portuguese   ")
        #expect(store.decks.last?.name == "Portuguese")
    }

    @Test("Blank names are refused", arguments: ["", " ", "\n", "\t  "])
    func refusesBlank(name: String) {
        let store = DeckStore()
        #expect(!store.canAdd(name))
        #expect(!store.add(named: name))
        #expect(store.decks.count == DeckStore.sample.count)
    }

    @Test("Duplicate names are refused, whatever the case",
          arguments: ["Kanji N5", "kanji n5", "KANJI N5", "  Kanji N5  "])
    func refusesDuplicates(name: String) {
        let store = DeckStore()
        #expect(!store.canAdd(name))
        #expect(!store.add(named: name))
    }
}
