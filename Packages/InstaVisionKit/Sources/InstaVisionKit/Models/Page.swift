import Foundation

/// A cursor-paginated Graph API response.
public struct Page<Element: Codable & Sendable>: Codable, Sendable {
    public struct Paging: Codable, Sendable {
        public struct Cursors: Codable, Sendable {
            public let before: String?
            public let after: String?
        }
        public let cursors: Cursors?
        public let next: URL?
        public let previous: URL?
    }

    public let data: [Element]
    public let paging: Paging?

    public init(data: [Element], paging: Paging? = nil) {
        self.data = data
        self.paging = paging
    }

    /// The URL for the next page, if there is one.
    public var nextURL: URL? { paging?.next }
}
