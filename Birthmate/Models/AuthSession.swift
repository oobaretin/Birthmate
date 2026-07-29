import Foundation

struct AuthSession: Codable, Sendable {
    let userID: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-60)
    }
}

struct AuthContext: Sendable {
    let session: AuthSession

    var userID: String { session.userID }
    var accessToken: String { session.accessToken }
}

enum AuthError: Error, LocalizedError {
    case notConfigured
    case missingIdentityToken
    case invalidResponse
    case serverError(String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Sign in is not configured yet."
        case .missingIdentityToken: return "Apple did not return a sign-in token."
        case .invalidResponse: return "Unexpected response from the auth service."
        case .serverError(let message): return message
        case .notSignedIn: return "Sign in with Apple to use this feature."
        }
    }
}
