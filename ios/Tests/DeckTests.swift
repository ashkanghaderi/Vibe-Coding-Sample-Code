import Testing
@testable import Flashcards

@Suite("Deck")
struct DeckTests {

    /// The badge on the deck list and the cards the review screen serves must
    /// come from the same place. They did not, which is Chapter 6.
    @Test("A deck's due badge matches the cards it will actually serve")
    func badgeMatchesCards() {
        for deck in DeckList.sampleDecks {
            #expect(
                deck.dueCount == deck.dueCards.count,
                "\(deck.name) shows \(deck.dueCount) due but serves \(deck.dueCards.count)"
            )
        }
    }

    @Test("A deck never claims more due cards than it has")
    func dueNeverExceedsTotal() {
        for deck in DeckList.sampleDecks {
            #expect(deck.dueCount <= deck.totalCount)
        }
    }
}
