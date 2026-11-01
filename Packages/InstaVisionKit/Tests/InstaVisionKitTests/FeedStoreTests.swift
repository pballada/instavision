import Foundation
import Testing
@testable import InstaVisionKit

private struct FailingService: InstagramService {
    let error: GraphAPIError
    func profile() async throws -> InstagramProfile { throw error }
    func media(limit: Int) async throws -> Page<InstagramMedia> { throw error }
    func media(nextPage url: URL) async throws -> Page<InstagramMedia> { throw error }
}

@MainActor @Suite struct FeedStoreTests {
    @Test func loadsFirstPageAndProfile() async {
        let store = FeedStore(service: DemoInstagramService(latency: .zero), pageSize: 10)
        await store.loadIfNeeded()
        #expect(store.phase == .loaded)
        #expect(store.profile?.username == "visionary.demo")
        #expect(store.posts.count == 10)
        #expect(store.hasMore)
    }

    @Test func loadsMoreNearTheEnd() async throws {
        let store = FeedStore(service: DemoInstagramService(totalPosts: 15, latency: .zero), pageSize: 10)
        await store.refresh()
        await store.loadMoreIfNeeded(after: store.posts[0])
        #expect(store.posts.count == 10, "far from the end, nothing loads")
        await store.loadMoreIfNeeded(after: try #require(store.posts.last))
        #expect(store.posts.count == 15)
        #expect(!store.hasMore)
    }

    @Test func authFailureRequestsReauthentication() async {
        let store = FeedStore(service: FailingService(error: .api(message: "Expired", code: 190, subcode: 463)))
        await store.refresh()
        #expect(store.phase == .failed("Expired"))
        #expect(store.needsReauthentication)
    }

    @Test func otherFailuresDoNotSignOut() async {
        let store = FeedStore(service: FailingService(error: .http(status: 503)))
        await store.refresh()
        #expect(store.needsReauthentication == false)
        if case .failed = store.phase {} else { Issue.record("expected failure, got \(store.phase)") }
    }
}
