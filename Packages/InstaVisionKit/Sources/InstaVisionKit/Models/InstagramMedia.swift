import Foundation

/// A single post, or a child of a carousel album (`GET /me/media`).
public struct InstagramMedia: Codable, Hashable, Identifiable, Sendable {
    public enum MediaType: String, Codable, Sendable {
        case image = "IMAGE"
        case video = "VIDEO"
        case carouselAlbum = "CAROUSEL_ALBUM"
    }

    public let id: String
    public let mediaType: MediaType
    public let mediaURL: URL?
    public let thumbnailURL: URL?
    public let permalink: URL?
    public let caption: String?
    public let timestamp: Date?
    public let likeCount: Int?
    public let commentsCount: Int?
    public let children: [InstagramMedia]

    public init(
        id: String,
        mediaType: MediaType,
        mediaURL: URL? = nil,
        thumbnailURL: URL? = nil,
        permalink: URL? = nil,
        caption: String? = nil,
        timestamp: Date? = nil,
        likeCount: Int? = nil,
        commentsCount: Int? = nil,
        children: [InstagramMedia] = []
    ) {
        self.id = id
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.thumbnailURL = thumbnailURL
        self.permalink = permalink
        self.caption = caption
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.commentsCount = commentsCount
        self.children = children
    }

    /// The best image to show in a grid: video thumbnail, first carousel item, or the media itself.
    public var previewURL: URL? {
        switch mediaType {
        case .image: mediaURL
        case .video: thumbnailURL ?? mediaURL
        case .carouselAlbum: mediaURL ?? children.first?.previewURL
        }
    }

    /// Items to page through in the detail view. Non-carousel posts are a single item.
    public var items: [InstagramMedia] {
        mediaType == .carouselAlbum && !children.isEmpty ? children : [self]
    }

    enum CodingKeys: String, CodingKey {
        case id, permalink, caption, timestamp, children
        case mediaType = "media_type"
        case mediaURL = "media_url"
        case thumbnailURL = "thumbnail_url"
        case likeCount = "like_count"
        case commentsCount = "comments_count"
    }

    private struct ChildrenEnvelope: Codable { let data: [InstagramMedia] }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        mediaType = try c.decode(MediaType.self, forKey: .mediaType)
        mediaURL = try c.decodeIfPresent(URL.self, forKey: .mediaURL)
        thumbnailURL = try c.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        permalink = try c.decodeIfPresent(URL.self, forKey: .permalink)
        caption = try c.decodeIfPresent(String.self, forKey: .caption)
        timestamp = try c.decodeIfPresent(Date.self, forKey: .timestamp)
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount)
        commentsCount = try c.decodeIfPresent(Int.self, forKey: .commentsCount)
        children = try c.decodeIfPresent(ChildrenEnvelope.self, forKey: .children)?.data ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(mediaType, forKey: .mediaType)
        try c.encodeIfPresent(mediaURL, forKey: .mediaURL)
        try c.encodeIfPresent(thumbnailURL, forKey: .thumbnailURL)
        try c.encodeIfPresent(permalink, forKey: .permalink)
        try c.encodeIfPresent(caption, forKey: .caption)
        try c.encodeIfPresent(timestamp, forKey: .timestamp)
        try c.encodeIfPresent(likeCount, forKey: .likeCount)
        try c.encodeIfPresent(commentsCount, forKey: .commentsCount)
        if !children.isEmpty { try c.encode(ChildrenEnvelope(data: children), forKey: .children) }
    }

    /// Fields requested from the Graph API.
    public static let fields = "id,media_type,media_url,thumbnail_url,permalink,caption,timestamp,like_count,comments_count,children{id,media_type,media_url,thumbnail_url}"
}
