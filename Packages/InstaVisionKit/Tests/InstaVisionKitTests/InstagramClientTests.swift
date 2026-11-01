import Foundation
import Testing
@testable import InstaVisionKit

@Suite(.serialized) struct InstagramClientTests {
    let client = InstagramClient(session: StubURLProtocol.session) { "TOKEN" }

    init() { StubURLProtocol.requests = [] }

    @Test func fetchesProfileWithFieldsAndToken() async throws {
        StubURLProtocol.handler = { _ in (200, Data(#"{"id":"1","username":"pau"}"#.utf8)) }
        let profile = try await client.profile()
        #expect(profile.username == "pau")

        let url = try #require(StubURLProtocol.requests.last?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.path == "/v23.0/me")
        #expect(items.contains(URLQueryItem(name: "access_token", value: "TOKEN")))
        #expect(items.contains(URLQueryItem(name: "fields", value: InstagramProfile.fields)))
    }

    @Test func nextPageReplacesStaleToken() async throws {
        StubURLProtocol.handler = { _ in (200, Data(#"{"data":[]}"#.utf8)) }
        let next = URL(string: "https://graph.instagram.com/v23.0/me/media?access_token=OLD&after=A&limit=24")!
        _ = try await client.media(nextPage: next)

        let url = try #require(StubURLProtocol.requests.last?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "access_token" }.map(\.value) == ["TOKEN"])
        #expect(items.contains(URLQueryItem(name: "after", value: "A")))
    }

    @Test func decodesApiErrors() async throws {
        StubURLProtocol.handler = { _ in
            (400, Data(#"{"error":{"message":"Invalid OAuth access token.","type":"OAuthException","code":190}}"#.utf8))
        }
        let error = await #expect(throws: GraphAPIError.self) { try await client.profile() }
        #expect(error?.isAuthenticationError == true)
        #expect(error?.errorDescription == "Invalid OAuth access token.")
    }

    @Test func missingTokenFailsWithoutNetwork() async throws {
        let anonymous = InstagramClient(session: StubURLProtocol.session) { nil }
        await #expect(throws: GraphAPIError.missingToken) { try await anonymous.profile() }
        #expect(StubURLProtocol.requests.isEmpty)
    }
}
