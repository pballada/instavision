import Foundation

/// An Instagram access token and when it expires.
public struct Credential: Codable, Equatable, Sendable {
    public var accessToken: String
    /// Long-lived tokens last 60 days. `nil` when unknown.
    public var expiresAt: Date?
    /// When the token was last refreshed (or first saved). Instagram only refreshes tokens older than 24 hours.
    public var refreshedAt: Date?

    public init(accessToken: String, expiresAt: Date? = nil, refreshedAt: Date? = nil) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshedAt = refreshedAt
    }
}

/// Persists the signed-in credential.
public protocol CredentialStore: Sendable {
    func load() async -> Credential?
    func save(_ credential: Credential) async throws
    func clear() async throws
}

/// A store that only lives in memory. Used for previews and tests.
public actor InMemoryCredentialStore: CredentialStore {
    private var credential: Credential?
    public init(_ credential: Credential? = nil) { self.credential = credential }
    public func load() -> Credential? { credential }
    public func save(_ credential: Credential) { self.credential = credential }
    public func clear() { credential = nil }
}
