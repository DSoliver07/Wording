import Foundation
import SwiftData

enum SampleData {
    /// Seeds the store with demo content once per install, and only if empty.
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "didSeedSampleData") else { return }
        defaults.set(true, forKey: "didSeedSampleData")

        let languageCount = (try? context.fetchCount(FetchDescriptor<Language>())) ?? 0
        guard languageCount == 0 else { return }

        seed(in: context)
    }

    @MainActor
    static func seed(in context: ModelContext) {
        // Relationships must only be linked after every model is inserted,
        // otherwise SwiftData silently drops them.
        let spanish = Language(title: "Spanish")
        let german = Language(title: "German")
        context.insert(spanish)
        context.insert(german)

        let vocabularies: [(Vocabulary, Language, [WordItem])] = [
            (Vocabulary(title: "Food & Dining"), spanish, [
                WordItem(id: 1, term: "queso", translation: "cheese", learned: true),
                WordItem(id: 2, term: "manzana", translation: "apple"),
                WordItem(id: 3, term: "pan", translation: "bread"),
            ]),
            (Vocabulary(title: "Travel"), spanish, [
                WordItem(id: 1, term: "aeropuerto", translation: "airport", learned: true),
                WordItem(id: 2, term: "maleta", translation: "suitcase"),
            ]),
            (Vocabulary(title: "Basics"), german, [
                WordItem(id: 1, term: "Hallo", translation: "hello", learned: true),
                WordItem(id: 2, term: "Danke", translation: "thank you"),
            ]),
        ]

        for (vocabulary, language, words) in vocabularies {
            context.insert(vocabulary)
            vocabulary.language = language
            for word in words {
                context.insert(word)
                word.vocabulary = vocabulary
            }
        }

        try? context.save()
    }
}

#if DEBUG
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Language.self,
            configurations: config
        )
        SampleData.seed(in: container.mainContext)
        return container
    }()
}
#endif
