import Foundation
import Testing
@testable import Wording

/// Tests for the per-vocabulary practice settings stored in UserDefaults.
struct PracticeOptionsTests {
    @Test func defaultsAreSensible() {
        let options = PracticeOptions()
        #expect(options.wordCount == 10)
        #expect(options.checkPunctuation == true)
        #expect(options.checkCapitalization == false)
    }

    @Test func loadForUnknownVocabularyReturnsDefaults() {
        let options = PracticeOptions.load(for: UUID())
        #expect(options == PracticeOptions())
    }

    @Test func savedOptionsRoundTrip() {
        let vocabularyID = UUID()
        var options = PracticeOptions()
        options.wordCount = 25
        options.checkPunctuation = false
        options.checkCapitalization = true
        options.save(for: vocabularyID)

        let loaded = PracticeOptions.load(for: vocabularyID)
        #expect(loaded == options)
    }

    @Test func optionsAreScopedPerVocabulary() {
        let firstID = UUID()
        var options = PracticeOptions()
        options.wordCount = 3
        options.save(for: firstID)

        // A different vocabulary is unaffected by the first one's settings.
        #expect(PracticeOptions.load(for: UUID()) == PracticeOptions())
        #expect(PracticeOptions.load(for: firstID).wordCount == 3)
    }
}
