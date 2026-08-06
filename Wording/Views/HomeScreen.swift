import SwiftUI

struct HomeScreen: View {
    @Environment(AppDataStore.self) private var store

    @State private var isAddingLanguage = false
    @State private var newLanguageTitle = ""
    @State private var languagePendingDeletion: Language?
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if store.languages.isEmpty {
                    ContentUnavailableView(
                        "No Languages",
                        systemImage: "globe",
                        description: Text("Tap + to create your first language.")
                    )
                } else {
                    languageList
                }
            }
            .navigationTitle("Wording")
            .navigationDestination(for: Language.self) { language in
                VocabularyListScreen(language: language)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newLanguageTitle = ""
                        isAddingLanguage = true
                    } label: {
                        Label("Add Language", systemImage: "plus")
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
            .alert("New Language", isPresented: $isAddingLanguage) {
                TextField("Title", text: $newLanguageTitle)
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    store.addLanguage(title: newLanguageTitle)
                }
            }
            .alert(
                "Delete Language",
                isPresented: Binding(
                    get: { languagePendingDeletion != nil },
                    set: { if !$0 { languagePendingDeletion = nil } }
                ),
                presenting: languagePendingDeletion
            ) { language in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    store.deleteLanguage(language)
                }
            } message: { language in
                Text("Are you sure you want to delete \(language.title)?")
            }
        }
    }

    private var languageList: some View {
        List {
            ForEach(store.languages) { language in
                NavigationLink(value: language) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language.title)
                            .font(.headline)
                        Text("^[\(language.vocabularies.count) vocabulary](inflect: true)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        languagePendingDeletion = language
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
    HomeScreen()
        .environment(AppDataStore.sample())
}
