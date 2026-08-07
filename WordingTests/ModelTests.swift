import Foundation
import SwiftData
import Testing
@testable import Wording

/// Tests for the SwiftData model layer: Language, Vocabulary, WordItem.
struct ModelTests {
    /// Fresh in-memory store per test so nothing touches the real database.
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Language.self, Vocabulary.self, WordItem.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    @Test func newLanguageHasTitleAndNoVocabularies() throws {
        let context = try makeContext()
        let language = Language(title: "Spanish")
        context.insert(language)

        #expect(language.title == "Spanish")
        #expect(language.vocabularies.isEmpty)
    }

    @Test func vocabularyLinksToLanguage() throws {
        let context = try makeContext()
        let language = Language(title: "German")
        context.insert(language)
        // Insert first, then set the relationship — SwiftData drops
        // relationship changes made on models not yet in a context.
        let vocabulary = Vocabulary(title: "Basics")
        context.insert(vocabulary)
        vocabulary.language = language

        #expect(vocabulary.language === language)
        #expect(language.vocabularies.count == 1)
        #expect(language.vocabularies.first === vocabulary)
    }

    @Test func vocabularyCountsReflectLearnedWords() throws {
        let context = try makeContext()
        let vocabulary = Vocabulary(title: "Food")
        context.insert(vocabulary)
        for index in 1...4 {
            let word = WordItem(id: index, term: "term\(index)", translation: "meaning\(index)")
            context.insert(word)
            vocabulary.words.append(word)
        }
        vocabulary.words.first { $0.id == 1 }?.learned = true
        vocabulary.words.first { $0.id == 3 }?.learned = true

        #expect(vocabulary.totalCount == 4)
        #expect(vocabulary.knownCount == 2)
    }

    @Test func emptyVocabularyHasZeroCounts() throws {
        let context = try makeContext()
        let vocabulary = Vocabulary(title: "Empty")
        context.insert(vocabulary)

        #expect(vocabulary.totalCount == 0)
        #expect(vocabulary.knownCount == 0)
    }

    @Test func wordDefaultsToNotLearned() throws {
        let word = WordItem(id: 1, term: "arbeit", translation: "work")
        #expect(word.learned == false)
    }

    @Test func deletingLanguageCascadesToVocabulariesAndWords() throws {
        let context = try makeContext()
        let language = Language(title: "Spanish")
        context.insert(language)
        let vocabulary = Vocabulary(title: "Travel")
        context.insert(vocabulary)
        vocabulary.language = language
        let word = WordItem(id: 1, term: "maleta", translation: "suitcase")
        context.insert(word)
        vocabulary.words.append(word)
        try context.save()

        context.delete(language)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Language>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Vocabulary>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<WordItem>()) == 0)
    }

    @Test func deletingVocabularyKeepsLanguage() throws {
        let context = try makeContext()
        let language = Language(title: "Spanish")
        context.insert(language)
        let vocabulary = Vocabulary(title: "Travel")
        context.insert(vocabulary)
        vocabulary.language = language
        try context.save()

        context.delete(vocabulary)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Language>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Vocabulary>()) == 0)
        #expect(language.vocabularies.isEmpty)
    }
}
