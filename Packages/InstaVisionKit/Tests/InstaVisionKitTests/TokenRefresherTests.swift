import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct TokenRefresherTests {
    let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test func refreshPolicy() {
        #expect(TokenRefresher.shouldRefresh(Credential(accessToken: "a"), now: now))
        #expect(!TokenRefresher.shouldRefresh(Credential(accessToken: "a", refreshedAt: now.addingTimeInterval(-3600)), now: now))
        #expect(TokenRefresher.shouldRefresh(Credential(accessToken: "a", refreshedAt: now.addingTimeInterval(-90_000)), now: now))
    }

    @Test func storesRefreshedToken() async throws {
        let stub = StubURLProtocol.makeSession { _ in
            (200, Data(#"{"access_token":"NEW","token_type":"bearer","expires_in":5183944}"#.utf8))
        }
        let store = InMemoryCredentialStore(Credential(accessToken: "OLD"))
        let now = self.now
        let refreshed = try await TokenRefresher(store: store, session: stub.session) { now }.refreshIfNeeded()

        #expect(refreshed?.accessToken == "NEW")
        #expect(await store.load()?.expiresAt == now.addingTimeInterval(5_183_944))
        let query = stub.requests.last?.url?.query() ?? ""
        #expect(query.contains("grant_type=ig_refresh_token"))
        #expect(query.contains("access_token=OLD"))
    }

    @Test func skipsRecentlyRefreshedTokens() async throws {
        let stub = StubURLProtocol.makeSession()
        let store = InMemoryCredentialStore(Credential(accessToken: "T", refreshedAt: now))
        let now = self.now
        let result = try await TokenRefresher(store: store, session: stub.session) { now }.refreshIfNeeded()
        #expect(result == nil)
        #expect(stub.requests.isEmpty)
    }
}
