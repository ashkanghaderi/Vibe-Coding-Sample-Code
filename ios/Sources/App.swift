import SwiftUI

@main
struct FlashcardsApp: App {
    var body: some Scene {
        WindowGroup { DeckList(openTo: ScreenshotState.current) }
    }
}

/// Which screen to open on launch, and in what state.
///
/// Read from launch arguments, which `simctl launch` writes into UserDefaults:
///
///     xcrun simctl launch <udid> <bundle> -screen review -revealed YES
///
/// This exists so screenshots can be taken by a script instead of by a person
/// tapping through the app. A screenshot nobody can reproduce is a screenshot
/// nobody can check. See Chapter 5.
///
/// It is inert in normal use: with no launch arguments, `current` is nil.
enum ScreenshotState {
    case review(deckNamed: String, revealed: Bool)

    static var current: ScreenshotState? {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "screen") == "review" else { return nil }
        return .review(
            deckNamed: defaults.string(forKey: "deck") ?? "Spanish — Verbs",
            revealed: defaults.bool(forKey: "revealed")
        )
    }
}

struct Deck: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var dueCount: Int
    var totalCount: Int
}

struct DeckList: View {
    var openTo: ScreenshotState? = nil

    @State private var path: [Deck] = []
    @State private var decks: [Deck] = [
        Deck(name: "Spanish — Verbs", dueCount: 12, totalCount: 240),
        Deck(name: "Spanish — Food", dueCount: 0, totalCount: 86),
        Deck(name: "Kanji N5", dueCount: 34, totalCount: 103),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            List(decks) { deck in
                NavigationLink(value: deck) {
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
            }
            .navigationDestination(for: Deck.self) {
                ReviewView(deck: $0, startRevealed: startRevealed)
            }
            .navigationTitle("Decks")
            .toolbar { Button("Add", systemImage: "plus") {} }
        }
        .onAppear(perform: applyScreenshotState)
    }

    private var startRevealed: Bool {
        if case .review(_, let revealed) = openTo { return revealed }
        return false
    }

    private func applyScreenshotState() {
        guard case .review(let name, _) = openTo,
              let deck = decks.first(where: { $0.name == name })
        else { return }
        path = [deck]
    }
}
