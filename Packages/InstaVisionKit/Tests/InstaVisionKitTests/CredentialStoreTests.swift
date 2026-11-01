import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct CredentialStoreTests {
    @Test func inMemoryStoreRoundTrips() async throws {
        let store = InMemoryCredentialStore()
        #expect(await store.load() == nil)
        let credential = Credential(accessToken: "abc", expiresAt: Date(timeIntervalSince1970: 100))
        try await store.save(credential)
        #expect(await store.load() == credential)
        try await store.clear()
        #expect(await store.load() == nil)
    }

    @Test func credentialEncodingIsStable() throws {
        let credential = Credential(accessToken: "abc", expiresAt: nil)
        let data = try JSONEncoder().encode(credential)
        #expect(try JSONDecoder().decode(Credential.self, from: data) == credential)
    }
}
