import Foundation
import Observation

/// The Reels in an account's media.
///
/// The Graph API has no separate Reels endpoint, so this filters the shared `FeedStore` and keeps
/// paging until there are enough Reels to show, even when an account mixes many posts in between.
@MainActor @Observable
public final class ReelsStore {
    public let feed: FeedStore
    /// How many Reels to have loaded before stopping, unless the account runs out of media.
    public var minimumReels: Int
    public private(set) var isFilling = false

    public init(feed: FeedStore, minimumReels: Int = 12) {
        self.feed = feed
        self.minimumReels = minimumReels
    }

    public var reels: [InstagramMedia] { feed.posts.filter(\.isReel) }

    public var hasMore: Bool { feed.hasMore }

    /// Loads the feed if needed, then pages until `minimumReels` Reels are available.
    public func loadIfNeeded() async {
        await feed.loadIfNeeded()
        await fill(upTo: minimumReels)
    }

    public func refresh() async {
        await feed.refresh()
        await fill(upTo: minimumReels)
    }

    /// Call when `reel` appears on screen; loads more when it is one of the last few.
    public func loadMoreIfNeeded(after reel: InstagramMedia, threshold: Int = 3) async {
        let reels = self.reels
        guard let index = reels.firstIndex(where: { $0.id == reel.id }),
              index >= reels.count - threshold else { return }
        await fill(upTo: reels.count + minimumReels / 2)
    }

    public func reel(after id: InstagramMedia.ID, offset: Int) -> InstagramMedia? {
        let reels = self.reels
        guard let index = reels.firstIndex(where: { $0.id == id }), reels.indices.contains(index + offset) else { return nil }
        return reels[index + offset]
    }

    /// Pages through the feed until `target` Reels are loaded or the feed ends.
    private func fill(upTo target: Int) async {
        guard !isFilling else { return }
        isFilling = true
        defer { isFilling = false }
        while reels.count < target, feed.hasMore, feed.phase == .loaded {
            let before = feed.posts.count
            await feed.loadMore()
            if feed.posts.count == before { break } // paging failed or returned nothing
        }
    }
}
