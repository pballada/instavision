import Foundation

/// A fake account with generated posts, so the app can be explored without signing in.
public struct DemoInstagramService: InstagramService {
    public let pageSize: Int
    public let totalPosts: Int
    /// Simulated network latency.
    public let latency: Duration

    public init(pageSize: Int = 24, totalPosts: Int = 60, latency: Duration = .milliseconds(350)) {
        self.pageSize = pageSize
        self.totalPosts = totalPosts
        self.latency = latency
    }

    public func profile() async throws -> InstagramProfile {
        try await Task.sleep(for: latency)
        return InstagramProfile(
            id: "demo",
            username: "visionary.demo",
            name: "Demo Account",
            accountType: .mediaCreator,
            profilePictureURL: Self.photo(id: 64, size: 300),
            followersCount: 12_480,
            followsCount: 312,
            mediaCount: totalPosts
        )
    }

    public func media(limit: Int) async throws -> Page<InstagramMedia> {
        try await page(offset: 0, limit: limit)
    }

    public func media(nextPage url: URL) async throws -> Page<InstagramMedia> {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let offset = items.first { $0.name == "offset" }?.value.flatMap(Int.init) ?? 0
        let limit = items.first { $0.name == "limit" }?.value.flatMap(Int.init) ?? pageSize
        return try await page(offset: offset, limit: limit)
    }

    private func page(offset: Int, limit: Int) async throws -> Page<InstagramMedia> {
        try await Task.sleep(for: latency)
        let end = min(offset + limit, totalPosts)
        let posts = (offset..<end).map(Self.post(index:))
        let next: URL? = end < totalPosts ? URL(string: "demo://media?offset=\(end)&limit=\(limit)") : nil
        return Page(data: posts, paging: .init(cursors: nil, next: next, previous: nil))
    }

    // MARK: - Sample content

    static let captions = [
        "Golden hour never misses 🌅", "Weekend in the mountains ⛰️", "Coffee first ☕️",
        "City lights, quiet nights", "Found this little corner of calm", "Saltwater therapy 🌊",
        "Details matter", "Long walks, longer shadows", "Snapshots from the road 🚗",
    ]

    /// Apple's public HLS sample stream, used for demo videos.
    static let sampleVideo = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")!

    static func photo(id: Int, size: Int = 1080) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/\(size)/\(size)")!
    }

    /// A 9:16 cover image, like a Reel thumbnail.
    static func verticalPhoto(id: Int) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/1080/1920")!
    }

    static let reelCaptions = [
        "POV: you finally nailed the shot 🎬", "60 seconds of pure calm 🌿", "Wait for it… 👀",
        "Morning routine, sped up ☀️", "This view though 🏔️", "Tiny details, big mood ✨",
    ]

    static func post(index: Int) -> InstagramMedia {
        let photoID = 10 + (index * 7) % 90
        let date = Date(timeIntervalSince1970: 1_790_000_000 - Double(index) * 86_400 * 2.5)
        let caption = captions[index % captions.count]
        let permalink = URL(string: "https://www.instagram.com/")
        let likes = 80 + (index * 37) % 900
        let comments = (index * 13) % 60

        // Every other post is a Reel, so the demo is Reels-first like the app.
        if index % 2 == 0 {
            return InstagramMedia(
                id: "demo-\(index)", mediaType: .video, productType: .reels, isSharedToFeed: index % 4 == 0,
                mediaURL: sampleVideo, thumbnailURL: verticalPhoto(id: photoID), permalink: permalink,
                caption: reelCaptions[(index / 2) % reelCaptions.count], timestamp: date,
                likeCount: likes * 6, commentsCount: comments * 3
            )
        }

        switch index % 7 {
        case 3:
            return InstagramMedia(
                id: "demo-\(index)", mediaType: .video, productType: .feed, mediaURL: sampleVideo,
                thumbnailURL: photo(id: photoID), permalink: permalink, caption: caption,
                timestamp: date, likeCount: likes, commentsCount: comments
            )
        case 5:
            let children = (0..<4).map { child in
                InstagramMedia(id: "demo-\(index)-\(child)", mediaType: .image, mediaURL: photo(id: photoID + child))
            }
            return InstagramMedia(
                id: "demo-\(index)", mediaType: .carouselAlbum, productType: .feed, mediaURL: children[0].mediaURL,
                permalink: permalink, caption: caption, timestamp: date,
                likeCount: likes, commentsCount: comments, children: children
            )
        default:
            return InstagramMedia(
                id: "demo-\(index)", mediaType: .image, productType: .feed, mediaURL: photo(id: photoID),
                permalink: permalink, caption: caption, timestamp: date,
                likeCount: likes, commentsCount: comments
            )
        }
    }
}
