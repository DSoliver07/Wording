import SwiftUI
import SwiftData

struct AddWordsScreen: View {
    @Environment(\.modelContext) private var modelContext

    let vocabulary: Vocabulary

    private var words: [WordItem] {
        vocabulary.words.sorted { $0.id < $1.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(words) { word in
                    WordBlock(word: word) {
                        deleteWord(word)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                addBlockButton
                    // New identity per count: the button fades out at its old
                    // spot and fades back in under the newly added block.
                    .id(words.count)
                    .transition(.opacity)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .animation(.easeInOut(duration: 0.35), value: words.count)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(vocabulary.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vocabulary.words.isEmpty {
                addWord()
            }
        }
        .onDisappear {
            deleteBlankWords()
        }
    }

    // Mutate vocabulary.words directly: relying on the inverse
    // (word.vocabulary / modelContext.delete) doesn't refresh the
    // relationship array until a save, so the UI wouldn't update.
    private func addWord() {
        let word = WordItem(id: vocabulary.words.count + 1, term: "", translation: "")
        modelContext.insert(word)
        vocabulary.words.append(word)
    }

    private func deleteWord(_ word: WordItem) {
        vocabulary.words.removeAll { $0 === word }
        modelContext.delete(word)
        renumberWords()
    }

    /// Keep ids sequential (1...n) so block numbers never show gaps.
    private func renumberWords() {
        for (index, word) in words.enumerated() {
            word.id = index + 1
        }
    }

    /// Blocks left completely empty are not real words — drop them on exit.
    private func deleteBlankWords() {
        let blanks = vocabulary.words.filter { word in
            word.term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && word.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        for word in blanks {
            deleteWord(word)
        }
    }

    private var addBlockButton: some View {
        Button {
            addWord()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
                .padding(14)
                .overlay(Circle().stroke(.tint.opacity(0.6), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
}

/// One editable word: numbered header with a delete button,
/// and capsule fields for the term and its meaning.
private struct WordBlock: View {
    @Bindable var word: WordItem
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("#\(word.id)")
                    .font(.title3.bold())
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            TextField("Term", text: $word.term)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(.primary.opacity(0.8), lineWidth: 1.5))
            TextField("Meaning", text: $word.translation)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(.primary.opacity(0.8), lineWidth: 1.5))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.primary.opacity(0.8), lineWidth: 1.5)
        }
    }
}

#Preview {
    let container = PreviewData.container
    let vocabulary = try! container.mainContext.fetch(FetchDescriptor<Vocabulary>()).first!
    return NavigationStack {
        AddWordsScreen(vocabulary: vocabulary)
    }
    .modelContainer(container)
}
