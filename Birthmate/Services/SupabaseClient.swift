import Foundation

struct SupabaseClient: Sendable {
    func request(
        path: String,
        query: String? = nil,
        method: String,
        body: Encodable? = nil,
        prefer: String? = nil,
        accessToken: String? = nil
    ) async throws -> Data {
        guard let baseURL = BirthmateSecrets.supabaseURL,
              let apiKey = BirthmateSecrets.supabaseAnonKey else {
            throw CommunityError.notConfigured
        }

        var url = baseURL.appendingPathComponent("rest/v1").appendingPathComponent(path)
        if let query, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.percentEncodedQuery = query
            if let built = components.url { url = built }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        let bearer = accessToken ?? apiKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer {
            request.setValue(prefer, forHTTPHeaderField: "Prefer")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw CommunityError.serverError(message)
        }
        return data
    }
}

private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encode = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encode(encoder) }
}

private extension String {
    var encodedForQuery: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

extension String {
    var supabaseQueryEncoded: String { encodedForQuery }
}
