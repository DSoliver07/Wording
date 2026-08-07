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
            LearnPlaceholder(vocabulary: vocabulary)
        } label: {
            capsuleLabel("Learn")
        }
        .buttonStyle(.plain)
    }

    private var addWordsButton: some View {
        NavigationLink {
            AddWordsScreen(vocabulary: vocabulary)
        } label: {
            capsuleLabel("Add words")
        }
        .buttonStyle(.plain)
    }

    private func capsuleLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            }
            .overlay(Capsule().stroke(.primary.opacity(0.8), lineWidth: 1.5))
    }
}

/// Temporary destination until the learn flow is implemented.
private struct LearnPlaceholder: View {
    let vocabulary: Vocabulary

    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "book",
            description: Text("Learning \(vocabulary.title) will be added later.")
        )
        .navigationTitle("Learn")
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
