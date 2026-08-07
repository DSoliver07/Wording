import Foundation

/// Per-vocabulary practice settings, stored in UserDefaults keyed by the
/// vocabulary's UUID so the SwiftData schema stays untouched.
struct PracticeOptions: Codable, Equatable {
    var wordCount: Int = 10
    var checkPunctuation: Bool = true
    var checkCapitalization: Bool = false

    static func load(for vocabularyID: UUID) -> PracticeOptions {
        guard let data = UserDefaults.standard.data(forKey: key(for: vocabularyID)),
              let options = try? JSONDecoder().decode(PracticeOptions.self, from: data)
        else {
            return PracticeOptions()
        }
        return options
    }

    func save(for vocabularyID: UUID) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key(for: vocabularyID))
    }

    private static func key(for vocabularyID: UUID) -> String {
        "practiceOptions-\(vocabularyID.uuidString)"
    }
}
