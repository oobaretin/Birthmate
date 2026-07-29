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
            let nonce = AppleSignInNonce.random()
            authStore.pendingAppleNonce = nonce
            request.requestedScopes = [.fullName, .email]
            request.nonce = AppleSignInNonce.sha256(nonce)
        } onCompletion: { result in
            let nonce = authStore.pendingAppleNonce
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    authStore.errorMessage = "Unexpected Apple sign-in response."
                    return
                }
                Task {
                    await authStore.handleAppleCredential(credential, nonce: nonce)
                }
            case .failure(let error):
                authStore.errorMessage = AppleSignInErrorHelper.message(for: error)
            }
        }
        .signInWithAppleButtonStyle(style)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(authStore.isLoading)
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
