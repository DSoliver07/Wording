import SwiftUI

@main
struct WordingApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var store = AppDataStore.sample()

    var body: some Scene {
        WindowGroup {
            HomeScreen()
                .environment(store)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
