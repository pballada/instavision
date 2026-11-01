import Foundation
import Testing
@testable import InstaVisionKit

/// Returns pages where only every `reelEvery`-th post is a Reel.
private struct SparseReelsService: InstagramService {
    let total: Int
    let reelEvery: Int

    func profile() async throws -> InstagramProfile { InstagramProfile(id: "1", username: "u") }
    func media(limit: Int) async throws -> Page<InstagramMedia> { page(0, limit) }
    func media(nextPage url: URL) async throws -> Page<InstagramMedia> {
        let offset = Int(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value ?? "0") ?? 0
        return page(offset, 5)
    }

    private func page(_ offset: Int, _ limit: Int) -> Page<InstagramMedia> {
        let end = min(offset + limit, total)
        let items = (offset..<end).map { i in
            InstagramMedia(id: "\(i)", mediaType: i % reelEvery == 0 ? .video : .image,
                           productType: i % reelEvery == 0 ? .reels : .feed)
        }
        let next = end < total ? URL(string: "test://media?offset=\(end)") : nil
        return Page(data: items, paging: .init(cursors: nil, next: next, previous: nil))
    }
}

@MainActor @Suite struct ReelsStoreTests {
    @Test func pagesUntilEnoughReels() async {
        let feed = FeedStore(service: SparseReelsService(total: 100, reelEvery: 10), pageSize: 5)
        let store = ReelsStore(feed: feed, minimumReels: 4)
        await store.loadIfNeeded()
        #expect(store.reels.count == 4)
        #expect(store.reels.allSatisfy { $0.isReel })
        #expect(feed.posts.count < 100, "stops paging once it has enough")
    }

    @Test func stopsWhenFeedEnds() async {
        let feed = FeedStore(service: SparseReelsService(total: 12, reelEvery: 10), pageSize: 5)
        let store = ReelsStore(feed: feed, minimumReels: 10)
        await store.loadIfNeeded()
        #expect(store.reels.map(\.id) == ["0", "10"])
        #expect(!store.hasMore)
    }

    @Test func loadsMoreNearTheLastReel() async throws {
        let feed = FeedStore(service: SparseReelsService(total: 200, reelEvery: 2), pageSize: 10)
        let store = ReelsStore(feed: feed, minimumReels: 6)
        await store.loadIfNeeded()
        let count = store.reels.count
        await store.loadMoreIfNeeded(after: store.reels[0])
        #expect(store.reels.count == count, "far from the end")
        await store.loadMoreIfNeeded(after: try #require(store.reels.last))
        #expect(store.reels.count > count)
    }

    @Test func neighbours() async {
        let feed = FeedStore(service: SparseReelsService(total: 20, reelEvery: 2), pageSize: 20)
        let store = ReelsStore(feed: feed, minimumReels: 1)
        await store.loadIfNeeded()
        #expect(store.reel(after: "2", offset: 1)?.id == "4")
        #expect(store.reel(after: "2", offset: -1)?.id == "0")
        #expect(store.reel(after: "0", offset: -1) == nil)
    }
}
