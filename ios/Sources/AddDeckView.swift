import SwiftUI

/// Naming a new deck.
struct AddDeckView: View {
    let store: DeckStore
    var onFinish: () -> Void = {}

    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Deck name", text: $name)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(create)
                } footer: {
                    if !name.isEmpty && !store.canAdd(name) {
                        Text("There is already a deck with that name.")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onFinish)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(!store.canAdd(name))
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func create() {
        guard store.add(named: name) else { return }
        onFinish()
    }
}
