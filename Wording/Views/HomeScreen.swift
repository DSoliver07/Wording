import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Language.title) private var languages: [Language]

    @State private var isAddingLanguage = false
    @State private var newLanguageTitle = ""
    @State private var languagePendingDeletion: Language?
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            List {
                Group {
                    Text("Select a language")
                        .font(.headline)
                        .padding(.leading, 4)
                    ForEach(languages) { language in
                        languageRow(language)
                    }
                    addLanguageRow
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                WordingTitleBlob()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Language.self) { language in
                VocabularyListScreen(language: language)
            }
            .toolbar {
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
                    addLanguage()
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
                    modelContext.delete(language)
                }
            } message: { language in
                Text("Are you sure you want to delete \(language.title)?")
            }
        }
    }

    private func addLanguage() {
        let trimmed = newLanguageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(Language(title: trimmed))
    }

    private func languageRow(_ language: Language) -> some View {
        HStack {
            Text(language.title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .overlay(Capsule().stroke(.primary.opacity(0.8)))
        .background(
            NavigationLink(value: language) { EmptyView() }
                .opacity(0)
        )
        .swipeActions(allowsFullSwipe: false) {
            Button {
                languagePendingDeletion = language
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    private var addLanguageRow: some View {
        Button {
            newLanguageTitle = ""
            isAddingLanguage = true
        } label: {
            Text("Add new language")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                }
                .overlay(Capsule().stroke(.secondary.opacity(0.5), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeScreen()
        .modelContainer(PreviewData.container)
}
