import SwiftUI
import SwiftData

struct LearningScreen: View {
    let vocabulary: Vocabulary

    @State private var isShowingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                NavigationLink {
                    PracticeScreen(vocabulary: vocabulary)
                } label: {
                    CapsuleButtonLabel(title: "Practice", alignment: .leading)
                }
                .buttonStyle(.plain)
                NavigationLink {
                    StartTestPlaceholder()
                } label: {
                    CapsuleButtonLabel(title: "Start test", alignment: .leading)
                }
                .buttonStyle(.plain)
                NavigationLink {
                    PracticeOptionsScreen(vocabulary: vocabulary)
                } label: {
                    CapsuleButtonLabel(title: "Options", alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Learning")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    isShowingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen()
        }
    }
}

/// Temporary destination until the test mode is implemented.
private struct StartTestPlaceholder: View {
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "checklist",
            description: Text("Tests will be added later.")
        )
        .navigationTitle("Test")
    }
}

#Preview {
    let container = PreviewData.container
    let vocabulary = try! container.mainContext.fetch(FetchDescriptor<Vocabulary>()).first!
    return NavigationStack {
        LearningScreen(vocabulary: vocabulary)
    }
    .modelContainer(container)
}
