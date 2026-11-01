import Foundation

/// Keeps a long-lived Instagram token alive.
///
/// Long-lived tokens last 60 days and can be refreshed once they are at least 24 hours old
/// (`GET /refresh_access_token?grant_type=ig_refresh_token`). Refreshing at most once a day keeps
/// the token valid as long as the app is opened every couple of months.
public struct TokenRefresher: Sendable {
    public static let refreshURL = URL(string: "https://graph.instagram.com/refresh_access_token")!
    public static let minimumAge: TimeInterval = 24 * 60 * 60

    private let store: any CredentialStore
    private let session: URLSession
    private let now: @Sendable () -> Date

    public init(store: any CredentialStore, session: URLSession = .shared, now: @escaping @Sendable () -> Date = Date.init) {
        self.store = store
        self.session = session
        self.now = now
    }

    public static func shouldRefresh(_ credential: Credential, now: Date) -> Bool {
        guard let refreshedAt = credential.refreshedAt else { return true }
        return now.timeIntervalSince(refreshedAt) >= minimumAge
    }

    /// Refreshes the stored token if due. Returns the new credential, or `nil` if nothing changed.
    @discardableResult
    public func refreshIfNeeded() async throws -> Credential? {
        guard let credential = await store.load(), Self.shouldRefresh(credential, now: now()) else { return nil }

        var components = URLComponents(url: Self.refreshURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "ig_refresh_token"),
            URLQueryItem(name: "access_token", value: credential.accessToken),
        ]
        let (data, response) = try await session.data(from: components.url!)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if let envelope = try? JSONDecoder().decode(GraphAPIError.Envelope.self, from: data) {
                throw GraphAPIError.api(message: envelope.error.message, code: envelope.error.code, subcode: envelope.error.error_subcode)
            }
            throw GraphAPIError.http(status: status)
        }

        struct Response: Decodable {
            let access_token: String
            let expires_in: TimeInterval?
        }
        let body = try JSONDecoder().decode(Response.self, from: data)
        let date = now()
        let refreshed = Credential(
            accessToken: body.access_token,
            expiresAt: body.expires_in.map { date.addingTimeInterval($0) },
            refreshedAt: date
        )
        try await store.save(refreshed)
        return refreshed
    }
}
