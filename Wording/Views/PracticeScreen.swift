import SwiftUI
import SwiftData

struct PracticeScreen: View {
    @Environment(\.dismiss) private var dismiss

    let vocabulary: Vocabulary

    @State private var session: PracticeSession?

    var body: some View {
        Group {
            if let session {
                if session.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Practice",
                        systemImage: "checkmark.seal",
                        description: Text("Every word in this vocabulary is already learned. Add new words to keep going.")
                    )
                } else if session.phase == .finished {
                    completionView(for: session)
                } else if let exercise = session.current {
                    exerciseView(for: exercise, in: session)
                }
            } else {
                Color.clear
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if session == nil {
                session = PracticeSession(
                    vocabulary: vocabulary,
                    options: PracticeOptions.load(for: vocabulary.id)
                )
            }
        }
    }

    private func exerciseView(for exercise: PracticeSession.Exercise, in session: PracticeSession) -> some View {
        VStack(spacing: 24) {
            PracticeProgressBar(fraction: session.progress)
                .frame(height: 14)
            promptCard(exercise.prompt)
            if session.phase == .multipleChoice {
                ChoiceExerciseView(choices: exercise.choices, answer: exercise.answer) {
                    withAnimation {
                        session.completeCurrentChoice()
                    }
                }
                .id(exercise.id)
            } else {
                TypingExerciseView(
                    answerLabel: exercise.promptShowsTerm ? "meaning" : "term",
                    check: { session.isCorrect($0, for: exercise) },
                    answer: exercise.answer,
                    onMistake: { session.registerMistake() },
                    onComplete: {
                        withAnimation {
                            session.completeCurrentTyping()
                        }
                    }
                )
                .id(exercise.id)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func promptCard(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 30, weight: .bold))
            .minimumScaleFactor(0.4)
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(.systemGray6))
            }
    }

    private func completionView(for session: PracticeSession) -> some View {
        VStack(spacing: 20) {
            PracticeProgressBar(fraction: 1)
                .frame(height: 14)
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.green)
            Text("Practice complete!")
                .font(.title2.bold())
            if session.newlyLearnedCount > 0 {
                Text("You learned \(session.newlyLearnedCount) new word\(session.newlyLearnedCount == 1 ? "" : "s").")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                CapsuleButtonLabel(title: "Done")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

/// Session tracker: a capsule that fills green as exercises are completed.
private struct PracticeProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemBackground))
                Rectangle()
                    .fill(.green.opacity(0.75))
                    .frame(width: proxy.size.width * fraction)
            }
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.primary.opacity(0.8), lineWidth: 1.2))
        }
        .animation(.easeInOut(duration: 0.3), value: fraction)
    }
}

/// The four-option grid; wrong taps stay highlighted dark red, the right
/// one turns green before advancing.
private struct ChoiceExerciseView: View {
    let choices: [String]
    let answer: String
    let onCorrect: () -> Void

    @State private var wrongChoices: Set<String> = []
    @State private var isSolved = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose the correct word")
                .font(.headline.bold())
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        select(choice)
                    } label: {
                        Text(choice)
                            .font(.title3.bold())
                            .foregroundStyle(wrongChoices.contains(choice) ? Color.white : Color.primary)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .frame(maxWidth: .infinity, minHeight: 110)
                            .background {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(fillColor(for: choice))
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSolved)
                }
            }
        }
    }

    private func fillColor(for choice: String) -> Color {
        if isSolved && choice == answer {
            Color.green.opacity(0.8)
        } else if wrongChoices.contains(choice) {
            Color(red: 0.42, green: 0.07, blue: 0.07)
        } else {
            Color(.systemGray6)
        }
    }

    private func select(_ choice: String) {
        if choice == answer {
            isSolved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onCorrect()
            }
        } else {
            wrongChoices.insert(choice)
        }
    }
}

/// The underlined answer field. A wrong entry flashes red, then the solution
/// appears as the placeholder and must be typed before moving on.
private struct TypingExerciseView: View {
    let answerLabel: String
    let check: (String) -> Bool
    let answer: String
    let onMistake: () -> Void
    let onComplete: () -> Void

    @State private var text = ""
    @State private var showsSolution = false
    @State private var fieldState: FieldState = .neutral
    @FocusState private var isFocused: Bool

    private enum FieldState {
        case neutral, wrong, correct
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(showsSolution ? "Type the shown solution to continue" : "Type the \(answerLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField(showsSolution ? answer : "", text: $text)
                .font(.title2.bold())
                .foregroundStyle(textColor)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.primary)
                        .frame(height: 2)
                }
        }
        .padding(.top, 30)
        .onAppear {
            isFocused = true
        }
    }

    private var textColor: Color {
        switch fieldState {
        case .neutral: Color.primary
        case .wrong: Color(red: 0.6, green: 0.1, blue: 0.1)
        case .correct: Color.green
        }
    }

    private func submit() {
        guard fieldState != .correct else { return }
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            isFocused = true
            return
        }
        if check(text) {
            fieldState = .correct
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        } else {
            onMistake()
            fieldState = .wrong
            isFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                text = ""
                showsSolution = true
                fieldState = .neutral
                isFocused = true
            }
        }
    }
}

#Preview {
    let container = PreviewData.container
    let vocabulary = try! container.mainContext.fetch(FetchDescriptor<Vocabulary>()).first!
    return NavigationStack {
        PracticeScreen(vocabulary: vocabulary)
    }
    .modelContainer(container)
}
