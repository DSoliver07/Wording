import Foundation
import Observation

@Observable
final class AppDataStore {
    var languages: [Language]

    init(languages: [Language] = []) {
        self.languages = languages
    }

    // MARK: - Languages

    func addLanguage(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        languages.append(Language(title: trimmed))
    }

    func deleteLanguage(_ language: Language) {
        languages.removeAll { $0.id == language.id }
    }

    // MARK: - Vocabularies

    func addVocabulary(title: String, to language: Language) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        language.vocabularies.append(Vocabulary(title: trimmed, language: language))
    }

    func deleteVocabulary(_ vocabulary: Vocabulary) {
        vocabulary.language?.vocabularies.removeAll { $0.id == vocabulary.id }
    }
}

// MARK: - Sample Data

extension AppDataStore {
    /// In-memory placeholder data until SwiftData persistence is added.
    static func sample() -> AppDataStore {
        let spanish = Language(title: "Spanish")

        let food = Vocabulary(title: "Food & Dining", language: spanish)
        food.words = [
            WordItem(id: 1, term: "El queso", translation: "Cheese", learned: true),
            WordItem(id: 2, term: "La manzana", translation: "Apple"),
            WordItem(id: 3, term: "El pan", translation: "Bread", learned: true),
        ]
        food.words.forEach { $0.vocabulary = food }

        let travel = Vocabulary(title: "Travel", language: spanish)
        travel.words = [
            WordItem(id: 1, term: "El aeropuerto", translation: "Airport"),
            WordItem(id: 2, term: "La maleta", translation: "Suitcase"),
        ]
        travel.words.forEach { $0.vocabulary = travel }

        spanish.vocabularies = [food, travel]

        let german = Language(title: "German")

        let basics = Vocabulary(title: "Basics", language: german)
        basics.words = [
            WordItem(id: 1, term: "Hallo", translation: "Hello", learned: true),
            WordItem(id: 2, term: "Danke", translation: "Thank you"),
        ]
        basics.words.forEach { $0.vocabulary = basics }

        german.vocabularies = [basics]

        return AppDataStore(languages: [spanish, german])
    }
}
