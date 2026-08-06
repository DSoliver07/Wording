import Foundation
import Observation

@Observable
final class Language: Identifiable {
    var id: UUID
    var title: String
    var vocabularies: [Vocabulary]

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.vocabularies = []
    }
}

extension Language: Hashable {
    static func == (lhs: Language, rhs: Language) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
