import Foundation
import SwiftData

@Model
final class Language {
    @Attribute(.unique) var id: UUID
    var title: String
    @Relationship(deleteRule: .cascade, inverse: \Vocabulary.language)
    var vocabularies: [Vocabulary]

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.vocabularies = []
    }
}
