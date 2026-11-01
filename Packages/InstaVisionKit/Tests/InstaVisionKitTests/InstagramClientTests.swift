import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct InstagramClientTests {
    func client(_ stub: StubURLProtocol.Stub, token: String? = "TOKEN") -> InstagramClient {
        InstagramClient(session: stub.session) { token }
    }

    @Test func fetchesProfileWithFieldsAndToken() async throws {
        let stub = StubURLProtocol.makeSession { _ in (200, Data(#"{"id":"1","username":"pau"}"#.utf8)) }
        let profile = try await client(stub).profile()
        #expect(profile.username == "pau")

        let url = try #require(stub.requests.last?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(url.path == "/v23.0/me")
        #expect(items.contains(URLQueryItem(name: "access_token", value: "TOKEN")))
        #expect(items.contains(URLQueryItem(name: "fields", value: InstagramProfile.fields)))
    }

    @Test func nextPageReplacesStaleToken() async throws {
        let stub = StubURLProtocol.makeSession { _ in (200, Data(#"{"data":[]}"#.utf8)) }
        let next = URL(string: "https://graph.instagram.com/v23.0/me/media?access_token=OLD&after=A&limit=24")!
        _ = try await client(stub).media(nextPage: next)

        let url = try #require(stub.requests.last?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "access_token" }.map(\.value) == ["TOKEN"])
        #expect(items.contains(URLQueryItem(name: "after", value: "A")))
    }

    @Test func decodesApiErrors() async throws {
        let stub = StubURLProtocol.makeSession { _ in
            (400, Data(#"{"error":{"message":"Invalid OAuth access token.","type":"OAuthException","code":190}}"#.utf8))
        }
        let error = await #expect(throws: GraphAPIError.self) { try await client(stub).profile() }
        #expect(error?.isAuthenticationError == true)
        #expect(error?.errorDescription == "Invalid OAuth access token.")
    }

    @Test func missingTokenFailsWithoutNetwork() async throws {
        let stub = StubURLProtocol.makeSession()
        await #expect(throws: GraphAPIError.missingToken) { try await client(stub, token: nil).profile() }
        #expect(stub.requests.isEmpty)
    }
}
