#!/usr/bin/env swift
// Measures the two search implementations from Chapter 13.
//
// Deliberately NOT a test. A timing assertion in CI fails on a busy runner and
// passes on a quiet one, which teaches a team to re-run the build until it goes
// green - the single worst habit a test suite can produce. Benchmarks are run
// on purpose, by a person, and read.
//
//     swift scripts/bench-search.swift [deckCount] [cardsPerDeck]

import Foundation

struct Card { var front: String; var back: String }
struct Deck { var name: String }

func makeCorpus(decks: Int, cardsPerDeck: Int) -> ([Deck], [String: [Card]]) {
    var cards: [String: [Card]] = [:]
    let list = (0..<decks).map { index -> Deck in
        let deck = Deck(name: "Deck \(index)")
        cards[deck.name] = (0..<cardsPerDeck).map {
            Card(front: "Term \($0) of \(deck.name)",
                 back: "Meaning \($0) of \(deck.name)")
        }
        return deck
    }
    return (list, cards)
}

func naive(_ query: String, decks: [Deck], cards: [String: [Card]]) -> [Deck] {
    let needle = query.lowercased()
    guard !needle.isEmpty else { return decks }
    return decks.filter { deck in
        if deck.name.lowercased().contains(needle) { return true }
        return (cards[deck.name] ?? []).contains {
            $0.front.lowercased().contains(needle)
                || $0.back.lowercased().contains(needle)
        }
    }
}

struct Index {
    let entries: [(deck: Deck, haystack: String)]
    init(decks: [Deck], cards: [String: [Card]]) {
        entries = decks.map { deck in
            var haystack = deck.name.lowercased()
            for card in cards[deck.name] ?? [] {
                haystack += "\n" + card.front.lowercased()
                haystack += "\n" + card.back.lowercased()
            }
            return (deck, haystack)
        }
    }
    func results(for query: String) -> [Deck] {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return entries.map(\.deck) }
        return entries.filter { $0.haystack.contains(needle) }.map(\.deck)
    }
}

func time(_ label: String, _ body: () -> Void) -> Double {
    let clock = ContinuousClock()
    let elapsed = clock.measure(body)
    let ms = Double(elapsed.components.attoseconds) / 1e15
    print(String(format: "  %-38s %8.1f ms", (label as NSString).utf8String!, ms))
    return ms
}

let deckCount = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1])! : 2_000
let perDeck = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2])! : 20

let (decks, cards) = makeCorpus(decks: deckCount, cardsPerDeck: perDeck)
print("\(deckCount) decks x \(perDeck) cards = \(deckCount * perDeck) cards\n")

// Three query shapes, because they exercise completely different paths.
//
//   "meaning" matches nearly every deck on its first card, so the obvious
//   implementation exits early almost immediately.
//   "zzz" matches nothing, so nothing can exit early and every card is read.
//   "deck 1999" matches one deck late in the list.
let cases: [(String, [String])] = [
    ("common word, matches nearly everything",
     ["m", "me", "mea", "mean", "meani", "meanin", "meaning"]),
    ("matches nothing - no early exit anywhere",
     ["z", "zz", "zzz", "zzzq", "zzzqx", "zzzqxv", "zzzqxvb"]),
    ("matches one deck, late in the list",
     ["d", "de", "dec", "deck", "deck ", "deck 1", "deck 199"]),
]

var index: Index!
let buildTime = time("index: built once") { index = Index(decks: decks, cards: cards) }
print("")

for (label, keystrokes) in cases {
    print("  \(label), \(keystrokes.count) keystrokes:")
    let naiveTotal = time("    obvious") {
        for key in keystrokes { _ = naive(key, decks: decks, cards: cards) }
    }
    let queryTotal = time("    indexed (excluding build)") {
        for key in keystrokes { _ = index.results(for: key) }
    }
    let withBuild = buildTime + queryTotal
    print(String(format: "    obvious / indexed+build: %.2fx", naiveTotal / withBuild))
    print(String(format: "    obvious / indexed alone: %.2fx", naiveTotal / queryTotal))

    // What debouncing does: one search instead of seven, using the obvious
    // implementation. No new data structure, no new code path.
    let debounced = time("    obvious, debounced to 1 search") {
        _ = naive(keystrokes.last!, decks: decks, cards: cards)
    }
    print(String(format: "    obvious / debounced:     %.2fx\n", naiveTotal / debounced))
}
