import SwiftUI

struct VocabularyListScreen: View {
    @Environment(AppDataStore.self) private var store

    let language: Language

    @State private var isAddingVocabulary = false
    @State private var newVocabularyTitle = ""
    @State private var vocabularyPendingDeletion: Vocabulary?
    @State private var isShowingSettings = false

    var body: some View {
        Group {
            if language.vocabularies.isEmpty {
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
            StudyScreenPlaceholder(vocabulary: vocabulary)
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
                store.addVocabulary(title: newVocabularyTitle, to: language)
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
                store.deleteVocabulary(vocabulary)
            }
        } message: { _ in
            Text("Are you sure you want to delete this vocabulary list?")
        }
    }

    private var vocabularyList: some View {
        List {
            ForEach(language.vocabularies) { vocabulary in
                NavigationLink(value: vocabulary) {
                    HStack {
                        Text(vocabulary.title)
                            .font(.headline)
                        Spacer()
                        Text("\(vocabulary.knownCount)/\(vocabulary.totalCount)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: Capsule())
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

/// Temporary destination until the Study screen is implemented.
private struct StudyScreenPlaceholder: View {
    let vocabulary: Vocabulary

    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "book",
            description: Text("The study screen for \(vocabulary.title) will be added later.")
        )
        .navigationTitle(vocabulary.title)
    }
}

#Preview {
    let store = AppDataStore.sample()
    return NavigationStack {
        VocabularyListScreen(language: store.languages[0])
    }
    .environment(store)
}
