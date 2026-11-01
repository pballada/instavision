import Foundation

/// The signed-in Instagram professional account (`GET /me`).
public struct InstagramProfile: Codable, Hashable, Identifiable, Sendable {
    public enum AccountType: String, Codable, Sendable {
        case business = "BUSINESS"
        case mediaCreator = "MEDIA_CREATOR"
        case personal = "PERSONAL"
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = AccountType(rawValue: raw) ?? .unknown
        }
    }

    public let id: String
    public let username: String
    public let name: String?
    public let accountType: AccountType?
    public let profilePictureURL: URL?
    public let followersCount: Int?
    public let followsCount: Int?
    public let mediaCount: Int?

    public init(
        id: String,
        username: String,
        name: String? = nil,
        accountType: AccountType? = nil,
        profilePictureURL: URL? = nil,
        followersCount: Int? = nil,
        followsCount: Int? = nil,
        mediaCount: Int? = nil
    ) {
        self.id = id
        self.username = username
        self.name = name
        self.accountType = accountType
        self.profilePictureURL = profilePictureURL
        self.followersCount = followersCount
        self.followsCount = followsCount
        self.mediaCount = mediaCount
    }

    enum CodingKeys: String, CodingKey {
        case id, username, name
        case accountType = "account_type"
        case profilePictureURL = "profile_picture_url"
        case followersCount = "followers_count"
        case followsCount = "follows_count"
        case mediaCount = "media_count"
    }

    /// Fields requested from the Graph API.
    public static let fields = "id,username,name,account_type,profile_picture_url,followers_count,follows_count,media_count"
}
