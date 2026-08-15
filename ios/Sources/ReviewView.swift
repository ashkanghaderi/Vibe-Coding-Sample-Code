import SwiftUI

/// Reviewing one deck: show the front, reveal the back, move on.
struct ReviewView: View {
    let deck: Deck
    var startRevealed = false

    @State private var index = 0
    @State private var isRevealed = false
    @State private var generatorMessage: String?
    @State private var isGenerating = false

    private var cards: [Card] { deck.dueCards }
    private var card: Card? { cards.indices.contains(index) ? cards[index] : nil }

    var body: some View {
        VStack(spacing: 0) {
            if let card {
                ProgressView(value: Double(index), total: Double(max(cards.count, 1)))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 18) {
                    Text(card.front)
                        .font(.system(size: 34, weight: .semibold))
                        .multilineTextAlignment(.center)

                    if isRevealed {
                        Divider().frame(width: 120)
                        Text(card.back)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .padding(.horizontal, 24)
                .background(.background.secondary, in: .rect(cornerRadius: 18))
                .padding(.horizontal, 20)
                .onTapGesture { withAnimation(.snappy) { isRevealed = true } }

                Spacer()

                if isRevealed {
                    HStack(spacing: 12) {
                        answerButton("Again", tint: .orange)
                        answerButton("Good", tint: .blue)
                    }
                    .padding(.horizontal, 20)
                } else {
                    Text("Tap the card to reveal")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ContentUnavailableView {
                    Label("Nothing due", systemImage: "checkmark.circle")
                } description: {
                    Text("This deck has no cards waiting for review.")
                } actions: {
                    Button("Generate cards with AI", action: generate)
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating)
                    if let generatorMessage {
                        Text(generatorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 6)
                    }
                }
            }
        }
        .padding(.bottom, 28)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isRevealed = startRevealed }
    }

    private func answerButton(_ title: String, tint: Color) -> some View {
        // The width goes on the *label*, not on the button.
        //
        // `Button(title) { }.frame(maxWidth: .infinity)` compiles, and gives a
        // pill-shaped button floating in a full-width frame - the background is
        // drawn around the label, which never grew. Nothing catches this except
        // looking at it.
        Button { advance() } label: {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .controlSize(.large)
    }

    /// Asks the generator for cards.
    ///
    /// There is no key in this repository and no default, so on a machine that
    /// has not set FLASHCARDS_API_KEY this reports that and stops. That is the
    /// path most readers will see, and it is the honest one to show.
    private func generate() {
        guard let key = APIKey.fromEnvironment else {
            generatorMessage = "Set FLASHCARDS_API_KEY in the environment to "
                + "generate cards. There is no key in this repository."
            return
        }
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                let cards = try await RemoteCardGenerator(key: key)
                    .generate(count: 10, forDeckNamed: deck.name)
                generatorMessage = "Generated \(cards.count) cards."
            } catch {
                // `error` here can never contain the key; that is asserted by a
                // test rather than left to the reader to check. See Chapter 10.
                generatorMessage = "Could not generate cards: \(error)"
            }
        }
    }

    private func advance() {
        isRevealed = false
        index += 1
    }
}
