import Foundation
import Observation

@Observable
final class WordItem: Identifiable {
    var id: Int
    var term: String
    var translation: String
    var learned: Bool
    weak var vocabulary: Vocabulary?

    init(id: Int, term: String, translation: String, learned: Bool = false) {
        self.id = id
        self.term = term
        self.translation = translation
        self.learned = learned
    }
}
