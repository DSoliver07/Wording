import SwiftUI
import SwiftData

struct PracticeOptionsScreen: View {
    let vocabulary: Vocabulary

    @State private var options = PracticeOptions()

    var body: some View {
        Form {
            Section("Practice size") {
                Stepper(
                    "Words per session: \(options.wordCount)",
                    value: $options.wordCount,
                    in: 1...50
                )
            }
            Section {
                Toggle("Check punctuation", isOn: $options.checkPunctuation)
                Toggle("Check capitalization", isOn: $options.checkCapitalization)
            } header: {
                Text("Answer checking")
            } footer: {
                Text("When off, differences in punctuation or capitalization are ignored when checking typed answers.")
            }
        }
        .navigationTitle("Options")
        .onAppear {
            options = PracticeOptions.load(for: vocabulary.id)
        }
        .onChange(of: options) { _, newValue in
            newValue.save(for: vocabulary.id)
        }
    }
}

#Preview {
    let container = PreviewData.container
    let vocabulary = try! container.mainContext.fetch(FetchDescriptor<Vocabulary>()).first!
    return NavigationStack {
        PracticeOptionsScreen(vocabulary: vocabulary)
    }
    .modelContainer(container)
}
