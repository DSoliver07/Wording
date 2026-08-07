import Foundation
import SwiftData

@Model
final class Vocabulary {
    @Attribute(.unique) var id: UUID
    var title: String
    var language: Language?
    @Relationship(deleteRule: .cascade, inverse: \WordItem.vocabulary)
    var words: [WordItem]

    var knownCount: Int {
        words.filter(\.learned).count
    }

    var totalCount: Int {
        words.count
    }

    init(title: String, language: Language? = nil) {
        self.id = UUID()
        self.title = title
        self.language = language
        self.words = []
    }
}
