import Foundation

/// Client for the Instagram API with Instagram Login (`graph.instagram.com`).
public struct InstagramClient: InstagramService {
    public static let defaultBaseURL = URL(string: "https://graph.instagram.com/v23.0")!

    private let baseURL: URL
    private let session: URLSession
    private let token: @Sendable () async -> String?

    /// - Parameter token: Returns the current access token, so refreshed tokens are picked up.
    public init(
        baseURL: URL = InstagramClient.defaultBaseURL,
        session: URLSession = .shared,
        token: @escaping @Sendable () async -> String?
    ) {
        self.baseURL = baseURL
        self.session = session
        self.token = token
    }

    public func profile() async throws -> InstagramProfile {
        try await get("me", query: ["fields": InstagramProfile.fields])
    }

    public func media(limit: Int = 24) async throws -> Page<InstagramMedia> {
        try await get("me/media", query: ["fields": InstagramMedia.fields, "limit": String(limit)])
    }

    public func media(nextPage url: URL) async throws -> Page<InstagramMedia> {
        // `next` URLs already carry the token and fields; only replace the token with the current one.
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw GraphAPIError.invalidResponse
        }
        components.queryItems = (components.queryItems ?? []).filter { $0.name != "access_token" }
        return try await send(components)
    }

    // MARK: - Plumbing

    func get<T: Decodable>(_ path: String, query: [String: String]) async throws -> T {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false
        ) else { throw GraphAPIError.invalidResponse }
        components.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return try await send(components)
    }

    private func send<T: Decodable>(_ components: URLComponents) async throws -> T {
        guard let token = await token(), !token.isEmpty else { throw GraphAPIError.missingToken }
        var components = components
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "access_token", value: token)]
        guard let url = components.url else { throw GraphAPIError.invalidResponse }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GraphAPIError.invalidResponse }

        let decoder = GraphDecoder.make()
        guard (200..<300).contains(http.statusCode) else {
            if let envelope = try? decoder.decode(GraphAPIError.Envelope.self, from: data) {
                throw GraphAPIError.api(
                    message: envelope.error.message,
                    code: envelope.error.code,
                    subcode: envelope.error.error_subcode
                )
            }
            throw GraphAPIError.http(status: http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw GraphAPIError.invalidResponse
        }
    }
}
