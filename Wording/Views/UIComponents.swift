import SwiftUI

/// The app title over a soft purple blob whose shape slowly breathes and drifts.
struct WordingTitleBlob: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Text("Wording")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
                .padding(.horizontal, 46)
                .padding(.vertical, 26)
                .background {
                    ZStack {
                        Ellipse()
                            .fill(.purple.opacity(0.18))
                            .scaleEffect(
                                x: 1.10 + 0.05 * sin(t * 1.9 + 1.3),
                                y: 1.02 + 0.07 * cos(t * 2.6)
                            )
                            .rotationEffect(.degrees(4 * sin(t * 1.1)))
                        Ellipse()
                            .fill(.purple.opacity(0.28))
                            .scaleEffect(
                                x: 1.0 + 0.06 * sin(t * 2.3),
                                y: 1.0 + 0.05 * cos(t * 3.1 + 0.8)
                            )
                            .rotationEffect(.degrees(-3 * sin(t * 1.6 + 0.5)))
                    }
                }
        }
    }
}

/// A "known / total" capsule badge whose background fills with green
/// from the left in proportion to the learned fraction.
struct ProgressPill: View {
    let known: Int
    let total: Int

    var body: some View {
        Text("\(known) / \(total)")
            .font(.subheadline.weight(.semibold).monospacedDigit())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemBackground))
                        Rectangle()
                            .fill(.green.opacity(0.75))
                            .frame(width: proxy.size.width * fraction)
                    }
                    .clipShape(Capsule())
                }
            }
            .overlay(Capsule().stroke(.primary, lineWidth: 1.2))
    }

    private var fraction: CGFloat {
        guard total > 0 else { return 0 }
        return min(1, CGFloat(known) / CGFloat(total))
    }
}

#Preview {
    VStack(spacing: 24) {
        WordingTitleBlob()
        ProgressPill(known: 600, total: 1000)
            .frame(width: 500)
        ProgressPill(known: 0, total: 0)
    }
    .padding()
}
