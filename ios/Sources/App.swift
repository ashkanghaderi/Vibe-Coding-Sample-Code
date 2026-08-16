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
    case addDeck

    static var current: ScreenshotState? {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "screen") {
        case "review":
            return .review(
                deckNamed: defaults.string(forKey: "deck") ?? "Spanish — Verbs",
                revealed: defaults.bool(forKey: "revealed")
            )
        case "addDeck":
            return .addDeck
        default:
            return nil
        }
    }
}

struct Deck: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var totalCount: Int

    /// How many cards are waiting.
    ///
    /// Derived, not stored. It used to be a number typed into the sample data
    /// beside a completely separate list of cards, and the two disagreed for
    /// two chapters - the badge said 12, the review screen served 3. Keeping
    /// them in sync was never going to work; there is now only one of them.
    var dueCount: Int { dueCards.count }
}

struct DeckList: View {
    var openTo: ScreenshotState? = nil

    /// Scales with the text size. A hardcoded `height: 38` stayed 38 points
    /// while the row around it tripled, which turned a deliberate accent into
    /// a speck.
    @ScaledMetric(relativeTo: .body) private var accentHeight: CGFloat = 38

    @State private var path: [Deck] = []
    @State private var store = DeckStore(storage: FileDeckStorage(
        directory: URL.documentsDirectory))
    @State private var isAddingDeck = false

    var body: some View {
        NavigationStack(path: $path) {
            List(store.decks) { deck in
                NavigationLink(value: deck) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(deck.dueCount > 0 ? .blue : .secondary.opacity(0.3))
                        .frame(width: 4, height: accentHeight)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(deck.name).font(.body.weight(.medium))
                        Text("\(deck.totalCount) cards")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if deck.dueCount > 0 {
                        // Without a label VoiceOver reads "3". With it, the
                        // badge says what it counts.
                        Text("\(deck.dueCount)")
                            .accessibilityLabel("\(deck.dueCount) cards due")
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
            .toolbar {
                Button("Add", systemImage: "plus") { isAddingDeck = true }
            }
            .sheet(isPresented: $isAddingDeck) {
                AddDeckView(store: store) { isAddingDeck = false }
            }
            .overlay(alignment: .bottom) {
                if let loadError = store.loadError {
                    // Loud on purpose. The alternative - an empty deck list -
                    // looks like a working app that has forgotten everything.
                    Text("Your decks could not be loaded. The file has been "
                         + "kept.\n\(loadError)")
                        .font(.footnote)
                        .padding(12)
                        .background(.orange.opacity(0.25), in: .rect(cornerRadius: 10))
                        .padding()
                }
            }
        }
        .onAppear(perform: applyScreenshotState)
    }

    private var startRevealed: Bool {
        if case .review(_, let revealed) = openTo { return revealed }
        return false
    }

    private func applyScreenshotState() {
        switch openTo {
        case .review(let name, _):
            guard let deck = store.decks.first(where: { $0.name == name }) else { return }
            path = [deck]
        case .addDeck:
            isAddingDeck = true
        case nil:
            break
        }
    }
}
