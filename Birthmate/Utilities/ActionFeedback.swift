import SwiftUI

struct ActionFeedbackModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(BirthmateTheme.accent.gradient)
                        )
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: message)
            .onChange(of: message) { _, newValue in
                guard newValue != nil else { return }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        if message == newValue {
                            message = nil
                        }
                    }
                }
            }
    }
}

extension View {
    func actionFeedback(_ message: Binding<String?>) -> some View {
        modifier(ActionFeedbackModifier(message: message))
    }
}
