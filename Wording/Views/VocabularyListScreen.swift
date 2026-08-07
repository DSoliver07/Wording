import SwiftUI
import SwiftData

struct VocabularyListScreen: View {
    @Environment(\.modelContext) private var modelContext

    let language: Language

    @State private var isAddingVocabulary = false
    @State private var newVocabularyTitle = ""
    @State private var vocabularyPendingDeletion: Vocabulary?
    @State private var isShowingSettings = false

    // Relationship arrays are unordered in SwiftData, so sort for display.
    private var vocabularies: [Vocabulary] {
        language.vocabularies.sorted { $0.title < $1.title }
    }

    var body: some View {
        Group {
            if vocabularies.isEmpty {
                ContentUnavailableView(
                    "No Vocabularies",
                    systemImage: "text.book.closed",
                    description: Text("Tap + to create your first vocabulary list.")
                )
            } else {
                vocabularyList
            }
        }
        .navigationTitle(language.title)
        .navigationDestination(for: Vocabulary.self) { vocabulary in
            StudyScreen(vocabulary: vocabulary)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    newVocabularyTitle = ""
                    isAddingVocabulary = true
                } label: {
                    Label("Add Vocabulary", systemImage: "plus")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    isShowingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen()
        }
        .alert("New Vocabulary", isPresented: $isAddingVocabulary) {
            TextField("Title", text: $newVocabularyTitle)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                addVocabulary()
            }
        }
        .alert(
            "Delete Vocabulary",
            isPresented: Binding(
                get: { vocabularyPendingDeletion != nil },
                set: { if !$0 { vocabularyPendingDeletion = nil } }
            ),
            presenting: vocabularyPendingDeletion
        ) { vocabulary in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                modelContext.delete(vocabulary)
            }
        } message: { _ in
            Text("Are you sure you want to delete this vocabulary list?")
        }
    }

    private func addVocabulary() {
        let trimmed = newVocabularyTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let vocabulary = Vocabulary(title: trimmed)
        modelContext.insert(vocabulary)
        vocabulary.language = language
    }

    private var vocabularyList: some View {
        List {
            ForEach(vocabularies) { vocabulary in
                NavigationLink(value: vocabulary) {
                    HStack {
                        Text(vocabulary.title)
                            .font(.headline)
                        Spacer()
                        ProgressPill(known: vocabulary.knownCount, total: vocabulary.totalCount)
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        vocabularyPendingDeletion = vocabulary
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
        }
    }
}

#Preview {
    let container = PreviewData.container
    let language = try! container.mainContext.fetch(FetchDescriptor<Language>()).first!
    return NavigationStack {
        VocabularyListScreen(language: language)
    }
    .modelContainer(container)
}
