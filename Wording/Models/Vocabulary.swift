import Foundation
import Observation

@Observable
final class Vocabulary: Identifiable {
    var id: UUID
    var title: String
    weak var language: Language?
    var words: [WordItem]

    var knownCount: Int {
        words.filter { $0.learned }.count
    }

    var totalCount: Int {
        words.count
    }

    init(title: String, language: Language) {
        self.id = UUID()
        self.title = title
        self.language = language
        self.words = []
    }
}

extension Vocabulary: Hashable {
    static func == (lhs: Vocabulary, rhs: Vocabulary) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
