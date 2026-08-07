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
        let spanish = Language(title: "Spanish")
        context.insert(spanish)

        let food = Vocabulary(title: "Food & Dining", language: spanish)
        food.words = [
            WordItem(id: 1, term: "queso", translation: "cheese", learned: true),
            WordItem(id: 2, term: "manzana", translation: "apple"),
            WordItem(id: 3, term: "pan", translation: "bread"),
        ]

        let travel = Vocabulary(title: "Travel", language: spanish)
        travel.words = [
            WordItem(id: 1, term: "aeropuerto", translation: "airport", learned: true),
            WordItem(id: 2, term: "maleta", translation: "suitcase"),
        ]

        let german = Language(title: "German")
        context.insert(german)

        let basics = Vocabulary(title: "Basics", language: german)
        basics.words = [
            WordItem(id: 1, term: "Hallo", translation: "hello", learned: true),
            WordItem(id: 2, term: "Danke", translation: "thank you"),
        ]
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
