import SwiftUI
import SwiftData

@main
struct WordingApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Language.self, Vocabulary.self, WordItem.self)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
        SampleData.seedIfNeeded(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .modelContainer(container)
    }
}
