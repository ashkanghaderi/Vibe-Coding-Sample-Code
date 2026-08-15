import SwiftUI

@main
struct FlashcardsApp: App {
    var body: some Scene {
        WindowGroup { DeckList() }
    }
}

struct Deck: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var dueCount: Int
    var totalCount: Int
}

struct DeckList: View {
    @State private var decks: [Deck] = [
        Deck(name: "Spanish — Verbs", dueCount: 12, totalCount: 240),
        Deck(name: "Spanish — Food", dueCount: 0, totalCount: 86),
        Deck(name: "Kanji N5", dueCount: 34, totalCount: 103),
    ]

    var body: some View {
        NavigationStack {
            List(decks) { deck in
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(deck.dueCount > 0 ? .blue : .secondary.opacity(0.3))
                        .frame(width: 4, height: 38)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(deck.name).font(.body.weight(.medium))
                        Text("\(deck.totalCount) cards")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if deck.dueCount > 0 {
                        Text("\(deck.dueCount)")
                            .font(.footnote.weight(.semibold).monospacedDigit())
                            .padding(.horizontal, 9).padding(.vertical, 4)
                            .background(.blue, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Decks")
            .toolbar { Button("Add", systemImage: "plus") {} }
        }
    }
}
