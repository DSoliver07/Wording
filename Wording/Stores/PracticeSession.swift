import Foundation
import Observation
import SwiftData

/// Drives one practice run: every word is first matched from four choices in
/// both directions, then typed in both directions, and words that survive
/// typing without a mistake are marked learned.
@Observable
final class PracticeSession {
    enum Phase {
        case multipleChoice
        case typing
        case finished
    }

    struct Exercise: Identifiable {
        let id = UUID()
        let word: WordItem
        /// true → the prompt shows the term and the answer is the meaning.
        let promptShowsTerm: Bool
        var choices: [String] = []

        var prompt: String { promptShowsTerm ? word.term : word.translation }
        var answer: String { promptShowsTerm ? word.translation : word.term }
    }

    let options: PracticeOptions

    private let allWords: [WordItem]
    private let sessionWords: [WordItem]

    private(set) var phase: Phase = .multipleChoice
    private(set) var queue: [Exercise] = []
    private(set) var completedCount = 0
    private(set) var totalCount = 0
    /// Words newly marked learned during this session.
    private(set) var newlyLearnedCount = 0

    private var choiceDirectionsDone: [PersistentIdentifier: Set<Bool>] = [:]
    private var flaggedWords: [WordItem] = []
    private var cleanTypingDirections: [PersistentIdentifier: Set<Bool>] = [:]
    private var mistakenExercises: Set<UUID> = []

    var current: Exercise? { queue.first }
    var isEmpty: Bool { sessionWords.isEmpty }

    var progress: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    init(vocabulary: Vocabulary, options: PracticeOptions) {
        self.options = options
        let usable = vocabulary.words.filter {
            !$0.term.trimmingCharacters(in: .whitespaces).isEmpty
                && !$0.translation.trimmingCharacters(in: .whitespaces).isEmpty
        }
        allWords = usable
        sessionWords = Array(
            usable.filter { !$0.learned }.shuffled().prefix(options.wordCount)
        )
        queue = sessionWords
            .flatMap {
                [makeChoiceExercise(for: $0, promptShowsTerm: true),
                 makeChoiceExercise(for: $0, promptShowsTerm: false)]
            }
            .shuffled()
        // Both phases ask each word in both directions.
        totalCount = sessionWords.count * 4
        if queue.isEmpty {
            phase = .finished
        }
    }

    // MARK: - Multiple choice

    /// Distractors come from the whole vocabulary, not just the session words,
    /// so small sessions still get four options.
    private func makeChoiceExercise(for word: WordItem, promptShowsTerm: Bool) -> Exercise {
        var exercise = Exercise(word: word, promptShowsTerm: promptShowsTerm)
        let answer = exercise.answer
        let distractors = allWords
            .filter { $0 !== word }
            .map { promptShowsTerm ? $0.translation : $0.term }
            .filter { $0 != answer }
        var choices = [answer]
        for candidate in distractors.shuffled() where choices.count < 4 {
            if !choices.contains(candidate) {
                choices.append(candidate)
            }
        }
        exercise.choices = choices.shuffled()
        return exercise
    }

    /// Advance past a solved multiple-choice card. A word matched in both
    /// directions is flagged for the typing phase.
    func completeCurrentChoice() {
        guard phase == .multipleChoice, let exercise = queue.first else { return }
        queue.removeFirst()
        completedCount += 1
        let key = exercise.word.persistentModelID
        choiceDirectionsDone[key, default: []].insert(exercise.promptShowsTerm)
        if choiceDirectionsDone[key]?.count == 2 {
            flaggedWords.append(exercise.word)
        }
        if queue.isEmpty {
            startTypingPhase()
        }
    }

    private func startTypingPhase() {
        phase = .typing
        queue = flaggedWords
            .flatMap {
                [Exercise(word: $0, promptShowsTerm: true),
                 Exercise(word: $0, promptShowsTerm: false)]
            }
            .shuffled()
        if queue.isEmpty {
            phase = .finished
        }
    }

    // MARK: - Typing

    /// Record that the current typing card was answered wrong at least once.
    func registerMistake() {
        guard let exercise = queue.first else { return }
        mistakenExercises.insert(exercise.id)
    }

    /// Advance past a typing card that was eventually answered correctly.
    /// A card with a mistake is re-queued as a fresh attempt; a word typed
    /// cleanly in both directions becomes learned.
    func completeCurrentTyping() {
        guard phase == .typing, let exercise = queue.first else { return }
        queue.removeFirst()
        completedCount += 1
        if mistakenExercises.contains(exercise.id) {
            queue.append(Exercise(word: exercise.word, promptShowsTerm: exercise.promptShowsTerm))
            totalCount += 1
        } else {
            let key = exercise.word.persistentModelID
            cleanTypingDirections[key, default: []].insert(exercise.promptShowsTerm)
            if cleanTypingDirections[key]?.count == 2, !exercise.word.learned {
                exercise.word.learned = true
                newlyLearnedCount += 1
            }
        }
        if queue.isEmpty {
            phase = .finished
        }
    }

    func isCorrect(_ input: String, for exercise: Exercise) -> Bool {
        normalize(input) == normalize(exercise.answer)
    }

    private func normalize(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !options.checkCapitalization {
            result = result.lowercased()
        }
        if !options.checkPunctuation {
            result.removeAll(where: \.isPunctuation)
        }
        return result
    }
}
