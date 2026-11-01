import Foundation
import InstaVisionKit
import Observation

/// Who is signed in, and the feed for them.
@MainActor @Observable
final class AppSession {
    enum State: Equatable {
        case launching
        case signedOut
        case demo
        case signedIn
    }

    private(set) var state: State = .launching
    private(set) var feed: FeedStore?
    var signInError: String?
    private(set) var isSigningIn = false

    private let credentials: any CredentialStore
    private let defaults: UserDefaults
    private static let demoKey = "demoModeEnabled"

    init(credentials: any CredentialStore = KeychainCredentialStore(), defaults: UserDefaults = .standard) {
        self.credentials = credentials
        self.defaults = defaults
    }

    func restore() async {
        guard state == .launching else { return }
        if await credentials.load() != nil {
            startLiveFeed()
        } else if defaults.bool(forKey: Self.demoKey) {
            startDemo()
        } else {
            state = .signedOut
        }
    }

    /// Validates the token by loading the profile before saving it.
    func signIn(token rawToken: String) async {
        let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return }
        isSigningIn = true
        signInError = nil
        defer { isSigningIn = false }
        do {
            _ = try await InstagramClient { token }.profile()
            try await credentials.save(Credential(accessToken: token))
            defaults.set(false, forKey: Self.demoKey)
            startLiveFeed()
        } catch {
            signInError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func startDemo() {
        defaults.set(true, forKey: Self.demoKey)
        feed = FeedStore(service: DemoInstagramService())
        state = .demo
    }

    func signOut() async {
        try? await credentials.clear()
        defaults.set(false, forKey: Self.demoKey)
        feed = nil
        state = .signedOut
    }

    private func startLiveFeed() {
        let credentials = self.credentials
        feed = FeedStore(service: InstagramClient { await credentials.load()?.accessToken })
        state = .signedIn
        Task { await refreshTokenIfNeeded() }
    }

    /// Extends long-lived tokens. Failures are expected for tokens younger than 24 hours, and an
    /// actually expired token surfaces through the feed, so errors are ignored here.
    private func refreshTokenIfNeeded() async {
        _ = try? await TokenRefresher(store: credentials).refreshIfNeeded()
    }
}
