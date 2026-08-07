import SwiftUI
import SwiftData

struct StudyScreen: View {
    let vocabulary: Vocabulary

    @State private var isShowingSettings = false
    @State private var animatedFraction: Double = 0

    private var fraction: Double {
        guard vocabulary.totalCount > 0 else { return 0 }
        return Double(vocabulary.knownCount) / Double(vocabulary.totalCount)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("You have learned")
                    .font(.title2.bold())
                ProgressRing(fraction: animatedFraction)
                    .frame(width: 250, height: 250)
                    .frame(maxWidth: .infinity)
                VStack(spacing: 14) {
                    learnButton
                    addWordsButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle(vocabulary.title)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.9)) {
                animatedFraction = fraction
            }
        }
    }

    private var learnButton: some View {
        NavigationLink {
            LearningScreen(vocabulary: vocabulary)
        } label: {
            CapsuleButtonLabel(title: "Learn")
        }
        .buttonStyle(.plain)
    }

    private var addWordsButton: some View {
        NavigationLink {
            AddWordsScreen(vocabulary: vocabulary)
        } label: {
            CapsuleButtonLabel(title: "Add words")
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = PreviewData.container
    let vocabulary = try! container.mainContext.fetch(FetchDescriptor<Vocabulary>()).first!
    return NavigationStack {
        StudyScreen(vocabulary: vocabulary)
    }
    .modelContainer(container)
}
