import Testing
import Foundation
@testable import Flashcards

@Suite("DeckSearch")
struct DeckSearchTests {

    private func results(_ query: String,
                         in decks: [Deck] = DeckStore.sample) -> [Deck] {
        DeckSearch.results(for: query, in: decks, cards: { $0.dueCards })
    }

    @Test("An empty query returns everything")
    func emptyQuery() {
        #expect(results("").count == DeckStore.sample.count)
        #expect(results("   ").count == DeckStore.sample.count)
    }

    @Test("Deck names match, whatever the case",
          arguments: ["kanji", "KANJI", "Kanji N5", "  kanji  "])
    func matchesDeckName(query: String) {
        #expect(results(query).map(\.name) == ["Kanji N5"])
    }

    @Test("Card text matches too")
    func matchesCardText() {
        // "correr" is the back of a card in Spanish — Verbs, and appears in no
        // deck name.
        #expect(results("correr").map(\.name) == ["Spanish — Verbs"])
    }

    @Test("Results keep the original order")
    func preservesOrder() {
        let matched = results("s")
        let expected = DeckStore.sample.filter { matched.contains($0) }
        #expect(matched == expected)
    }

    @Test("Search scales to a corpus nobody would type by hand")
    func handlesALargeCorpus() {
        let decks = DeckSearchTests.corpus(count: 500)
        let found = DeckSearch.results(for: "Term 7 of Deck 499", in: decks,
                                       cards: DeckSearchTests.cards)
        #expect(found.map(\.name) == ["Deck 499"])
    }

    // MARK: - Corpus

    static func corpus(count: Int) -> [Deck] {
        (0..<count).map { Deck(name: "Deck \($0)", totalCount: 20) }
    }

    static func cards(for deck: Deck) -> [Card] {
        (0..<20).map { index in
            Card(front: "Term \(index) of \(deck.name)",
                 back: "Meaning \(index) of \(deck.name)")
        }
    }
}
