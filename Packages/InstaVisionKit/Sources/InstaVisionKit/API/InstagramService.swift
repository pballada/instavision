import Foundation

/// Anything that can provide an Instagram feed: the live Graph API or demo data.
public protocol InstagramService: Sendable {
    func profile() async throws -> InstagramProfile
    /// The first page of the account's media, newest first.
    func media(limit: Int) async throws -> Page<InstagramMedia>
    /// The page at a `paging.next` URL from a previous response.
    func media(nextPage url: URL) async throws -> Page<InstagramMedia>
}
