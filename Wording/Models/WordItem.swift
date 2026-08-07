import Foundation
import SwiftData

@Model
final class WordItem {
    // Unique within its vocabulary only (assigned by JSON import), not globally.
    var id: Int
    var term: String
    var translation: String
    var learned: Bool
    var vocabulary: Vocabulary?

    init(id: Int, term: String, translation: String, learned: Bool = false) {
        self.id = id
        self.term = term
        self.translation = translation
        self.learned = learned
    }
}
