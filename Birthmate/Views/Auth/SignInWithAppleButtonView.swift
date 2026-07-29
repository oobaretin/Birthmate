import AuthenticationServices
import SwiftUI

struct SignInWithAppleButtonView: View {
    @EnvironmentObject var authStore: AuthStore
    let style: SignInWithAppleButton.Style

    init(style: SignInWithAppleButton.Style = .black) {
        self.style = style
    }

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    return
                }
                Task {
                    await authStore.handleAppleCredential(credential)
                }
            case .failure(let error):
                authStore.errorMessage = error.localizedDescription
            }
        }
        .signInWithAppleButtonStyle(style)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SignedInBadge: View {
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        if authStore.isSignedIn {
            Label("Signed in with Apple", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(BirthmateTheme.accent)
        }
    }
}

#Preview {
    SignInWithAppleButtonView()
        .environmentObject(AuthStore())
        .padding()
}
