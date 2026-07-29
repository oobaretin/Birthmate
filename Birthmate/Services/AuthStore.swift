import AuthenticationServices
import Foundation

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingInviteUserID: String?

    private let authService = SupabaseAuthService()
    private let sessionKey = "auth_session"

    var isSignedIn: Bool { session != nil }
    var userID: String? { session?.userID }

    init() {
        restoreSession()
    }

    func authContext() throws -> AuthContext {
        guard let session else { throw AuthError.notSignedIn }
        return AuthContext(session: session)
    }

    func validSession() async throws -> AuthSession {
        if let session, !session.isExpired {
            return session
        }
        guard let session else { throw AuthError.notSignedIn }
        let refreshed = try await authService.refreshSession(session)
        persist(refreshed)
        return refreshed
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        guard BirthmateSecrets.isCommunityConfigured else {
            errorMessage = AuthError.notConfigured.localizedDescription
            return
        }

        guard let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            errorMessage = AuthError.missingIdentityToken.localizedDescription
            return
        }

        do {
            let newSession = try await authService.signInWithApple(idToken: idToken)
            persist(newSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleInviteURL(_ url: URL) {
        guard url.scheme == "birthmate",
              url.host == "friend",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let userID = components.queryItems?.first(where: { $0.name == "user" })?.value else {
            return
        }
        pendingInviteUserID = userID
    }

    func signOut() {
        session = nil
        KeychainStore.delete(account: sessionKey)
    }

    private func restoreSession() {
        guard let data = KeychainStore.load(account: sessionKey),
              let saved = try? JSONDecoder().decode(AuthSession.self, from: data) else {
            return
        }
        session = saved
    }

    private func persist(_ session: AuthSession) {
        self.session = session
        if let data = try? JSONEncoder().encode(session) {
            try? KeychainStore.save(data, account: sessionKey)
        }
    }
}
