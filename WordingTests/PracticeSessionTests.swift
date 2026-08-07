import Foundation
import SwiftData
import Testing
@testable import Wording

/// Tests for the practice engine: word selection, the multiple-choice phase,
/// the typing phase, mistake handling, and answer checking.
struct PracticeSessionTests {
    /// Keeps the in-memory store alive for the duration of a test — models
    /// detach if their container deallocates mid-test.
    private struct Fixture {
        let container: ModelContainer
        let context: ModelContext
        let vocabulary: Vocabulary
    }

    private func makeFixture(
        wordCount: Int = 0,
        terms: [(term: String, translation: String)]? = nil
    ) throws -> Fixture {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Language.self, Vocabulary.self, WordItem.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let vocabulary = Vocabulary(title: "Test")
        context.insert(vocabulary)
        let pairs = terms ?? (1...max(wordCount, 1)).map { ("term\($0)", "meaning\($0)") }
        if wordCount > 0 || terms != nil {
            for (index, pair) in pairs.enumerated() {
                let word = WordItem(id: index + 1, term: pair.0, translation: pair.1)
                context.insert(word)
                vocabulary.words.append(word)
            }
        }
        return Fixture(container: container, context: context, vocabulary: vocabulary)
    }

    /// Answer every remaining card so the session reaches the given phase.
    private func advance(_ session: PracticeSession, until phase: PracticeSession.Phase) {
        while session.phase == .multipleChoice, phase != .multipleChoice {
            session.completeCurrentChoice()
        }
        while session.phase == .typing, phase == .finished {
            session.completeCurrentTyping()
        }
    }

    // MARK: - Word selection

    @Test func sessionAsksEachWordFourTimes() throws {
        let fixture = try makeFixture(wordCount: 3)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        // Two multiple-choice + two typing cards per word.
        #expect(session.totalCount == 12)
        #expect(session.queue.count == 6)
        #expect(session.phase == .multipleChoice)
    }

    @Test func sessionRespectsWordCountOption() throws {
        let fixture = try makeFixture(wordCount: 5)
        var options = PracticeOptions()
        options.wordCount = 2
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: options)

        #expect(session.totalCount == 8)
        #expect(session.queue.count == 4)
    }

    @Test func learnedWordsAreExcluded() throws {
        let fixture = try makeFixture(wordCount: 3)
        fixture.vocabulary.words.first { $0.id == 1 }?.learned = true
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        #expect(session.totalCount == 8)
    }

    @Test func blankSidedWordsAreExcluded() throws {
        let fixture = try makeFixture(
            terms: [("arbeit", "work"), ("incomplete", "  ")]
        )
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        #expect(session.totalCount == 4)
    }

    @Test func fullyLearnedVocabularyYieldsEmptySession() throws {
        let fixture = try makeFixture(wordCount: 2)
        for word in fixture.vocabulary.words {
            word.learned = true
        }
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        #expect(session.isEmpty)
        #expect(session.phase == .finished)
        #expect(session.current == nil)
    }

    // MARK: - Multiple choice phase

    @Test func choiceCardsCoverBothDirectionsOfEveryWord() throws {
        let fixture = try makeFixture(wordCount: 4)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        var directions: [String: Set<Bool>] = [:]
        for exercise in session.queue {
            directions[exercise.word.term, default: []].insert(exercise.promptShowsTerm)
        }
        #expect(directions.count == 4)
        let allBothDirections = directions.values.allSatisfy { $0 == [true, false] }
        #expect(allBothDirections)
    }

    @Test func choicesContainTheAnswerWithoutDuplicates() throws {
        let fixture = try makeFixture(wordCount: 6)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        for exercise in session.queue {
            #expect(exercise.choices.contains(exercise.answer))
            #expect(exercise.choices.count == 4)
            #expect(Set(exercise.choices).count == exercise.choices.count)
        }
    }

    @Test func smallVocabularyGetsFewerChoices() throws {
        let fixture = try makeFixture(wordCount: 2)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        for exercise in session.queue {
            #expect(exercise.choices.count == 2)
            #expect(exercise.choices.contains(exercise.answer))
        }
    }

    @Test func finishingChoicesStartsTypingPhaseWithAllWords() throws {
        let fixture = try makeFixture(wordCount: 3)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        advance(session, until: .typing)

        #expect(session.phase == .typing)
        #expect(session.queue.count == 6)
        #expect(session.completedCount == 6)
    }

    // MARK: - Typing phase and learning

    @Test func cleanTypingMarksWordsLearned() throws {
        let fixture = try makeFixture(wordCount: 3)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        advance(session, until: .finished)

        #expect(session.phase == .finished)
        #expect(session.progress == 1)
        #expect(session.newlyLearnedCount == 3)
        // Evaluated outside #expect: rethrows calls confuse the macro expansion.
        let allLearned = fixture.vocabulary.words.allSatisfy(\.learned)
        #expect(allLearned)
    }

    @Test func mistakeRequeuesExerciseAndDelaysLearning() throws {
        let fixture = try makeFixture(wordCount: 1)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())
        advance(session, until: .typing)
        let word = fixture.vocabulary.words[0]

        // First typing card is answered wrong once, then completed.
        session.registerMistake()
        session.completeCurrentTyping()

        // The failed direction was re-queued: 2 remaining instead of 1.
        #expect(session.queue.count == 2)
        #expect(session.totalCount == 5)
        #expect(word.learned == false)

        // Second direction passes cleanly — still not learned, one redo pending.
        session.completeCurrentTyping()
        #expect(word.learned == false)

        // The redo passes cleanly — now the word is learned.
        session.completeCurrentTyping()
        #expect(word.learned == true)
        #expect(session.newlyLearnedCount == 1)
        #expect(session.phase == .finished)
        #expect(session.progress == 1)
    }

    @Test func progressGrowsMonotonically() throws {
        let fixture = try makeFixture(wordCount: 2)
        let session = PracticeSession(vocabulary: fixture.vocabulary, options: PracticeOptions())

        var lastProgress = session.progress
        while session.phase != .finished {
            if session.phase == .multipleChoice {
                session.completeCurrentChoice()
            } else {
                session.completeCurrentTyping()
            }
            #expect(session.progress >= lastProgress)
            lastProgress = session.progress
        }
        #expect(lastProgress == 1)
    }

    // MARK: - Answer checking

    /// Bundles the session with its fixture so the store stays alive as long
    /// as the session is in use.
    private struct SessionFixture {
        let fixture: Fixture
        let session: PracticeSession
    }

    /// Term and translation are identical so the expected answer is the same
    /// whichever direction the shuffled exercise happens to ask.
    private func makeSession(word: String, options: PracticeOptions) throws -> SessionFixture {
        let fixture = try makeFixture(terms: [(word, word)])
        return SessionFixture(
            fixture: fixture,
            session: PracticeSession(vocabulary: fixture.vocabulary, options: options)
        )
    }

    @Test func capitalizationIsIgnoredByDefault() throws {
        let run = try makeSession(word: "Hallo", options: PracticeOptions())
        let session = run.session
        let exercise = try #require(session.current)

        #expect(session.isCorrect("hallo", for: exercise))
        #expect(session.isCorrect("HALLO", for: exercise))
    }

    @Test func capitalizationCheckRejectsWrongCase() throws {
        var options = PracticeOptions()
        options.checkCapitalization = true
        let run = try makeSession(word: "Hallo", options: options)
        let session = run.session
        let exercise = try #require(session.current)

        #expect(session.isCorrect("Hallo", for: exercise))
        #expect(!session.isCorrect("hallo", for: exercise))
    }

    @Test func punctuationIsCheckedByDefault() throws {
        let run = try makeSession(word: "don't", options: PracticeOptions())
        let session = run.session
        let exercise = try #require(session.current)

        #expect(session.isCorrect("don't", for: exercise))
        #expect(!session.isCorrect("dont", for: exercise))
    }

    @Test func punctuationCheckCanBeDisabled() throws {
        var options = PracticeOptions()
        options.checkPunctuation = false
        let run = try makeSession(word: "don't", options: options)
        let session = run.session
        let exercise = try #require(session.current)

        #expect(session.isCorrect("dont", for: exercise))
    }

    @Test func surroundingWhitespaceIsIgnored() throws {
        let run = try makeSession(word: "work", options: PracticeOptions())
        let session = run.session
        let exercise = try #require(session.current)

        #expect(session.isCorrect("  work  ", for: exercise))
    }
}
