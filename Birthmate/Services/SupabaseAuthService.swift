import Foundation

struct SupabaseAuthService: Sendable {
    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let user: UserResponse

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case user
        }
    }

    private struct UserResponse: Decodable {
        let id: String
    }

    private struct AuthErrorResponse: Decodable {
        let message: String?
        let errorDescription: String?
        let error: String?
        let msg: String?

        enum CodingKeys: String, CodingKey {
            case message
            case errorDescription = "error_description"
            case error
            case msg
        }

        var bestMessage: String? {
            message ?? errorDescription ?? msg ?? error
        }
    }

    private struct AppleTokenBody: Encodable {
        let provider = "apple"
        let idToken: String
        let nonce: String

        enum CodingKeys: String, CodingKey {
            case provider
            case idToken = "id_token"
            case nonce
        }
    }

    private struct RefreshBody: Encodable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        try await tokenRequest(
            grantType: "id_token",
            body: AppleTokenBody(idToken: idToken, nonce: nonce)
        )
    }

    func refreshSession(_ session: AuthSession) async throws -> AuthSession {
        try await tokenRequest(
            grantType: "refresh_token",
            body: RefreshBody(refreshToken: session.refreshToken)
        )
    }

    private func tokenRequest(grantType: String, body: Encodable) async throws -> AuthSession {
        guard let baseURL = BirthmateSecrets.supabaseURL,
              let apiKey = BirthmateSecrets.supabaseAnonKey else {
            throw AuthError.notConfigured
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: grantType)]
        guard let url = components?.url else { throw AuthError.invalidResponse }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnyEncodable(body))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = parseErrorMessage(from: data) ?? "Sign in failed (HTTP \(http.statusCode))."
            throw AuthError.serverError(message)
        }

        do {
            let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
            return AuthSession(
                userID: decoded.user.id,
                accessToken: decoded.accessToken,
                refreshToken: decoded.refreshToken,
                expiresAt: Date().addingTimeInterval(TimeInterval(decoded.expiresIn))
            )
        } catch {
            throw AuthError.serverError("Could not read the sign-in response from the server.")
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(AuthErrorResponse.self, from: data),
           let message = decoded.bestMessage {
            return message
        }
        return String(data: data, encoding: .utf8)
    }
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
