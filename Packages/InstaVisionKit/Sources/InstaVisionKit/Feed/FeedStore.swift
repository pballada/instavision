import Foundation
import Observation

/// Loads the profile and media for an account and pages through it on demand.
@MainActor @Observable
public final class FeedStore {
    public enum Phase: Equatable {
        case idle, loading, loaded
        case failed(String)
    }

    public private(set) var profile: InstagramProfile?
    public private(set) var posts: [InstagramMedia] = []
    public private(set) var phase: Phase = .idle
    public private(set) var isLoadingMore = false
    /// Set when the service rejected the token, so the app can sign out.
    public private(set) var needsReauthentication = false
    public var hasMore: Bool { nextURL != nil }

    private let service: any InstagramService
    private let pageSize: Int
    private var nextURL: URL?
    /// Bumped on every refresh so results from an older load are dropped.
    private var generation = 0

    public init(service: any InstagramService, pageSize: Int = 24) {
        self.service = service
        self.pageSize = pageSize
    }

    /// Loads the first page unless already loaded.
    public func loadIfNeeded() async {
        guard phase == .idle else { return }
        await refresh()
    }

    /// Reloads the profile and the first page.
    public func refresh() async {
        generation += 1
        let current = generation
        if posts.isEmpty { phase = .loading }
        do {
            async let profile = service.profile()
            async let page = service.media(limit: pageSize)
            let (loadedProfile, firstPage) = try await (profile, page)
            guard current == generation else { return }
            self.profile = loadedProfile
            self.posts = firstPage.data
            self.nextURL = firstPage.nextURL
            phase = .loaded
        } catch {
            guard current == generation else { return }
            fail(with: error)
        }
    }

    /// Call when `post` appears on screen; fetches the next page once the end is close.
    public func loadMoreIfNeeded(after post: InstagramMedia, threshold: Int = 6) async {
        guard let index = posts.firstIndex(where: { $0.id == post.id }),
              index >= posts.count - threshold else { return }
        await loadMore()
    }

    public func loadMore() async {
        guard let nextURL, !isLoadingMore, phase == .loaded else { return }
        let current = generation
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await service.media(nextPage: nextURL)
            guard current == generation else { return }
            let known = Set(posts.map(\.id))
            posts += page.data.filter { !known.contains($0.id) }
            self.nextURL = page.nextURL
        } catch {
            guard current == generation else { return }
            if (error as? GraphAPIError)?.isAuthenticationError == true { fail(with: error) }
            // Other paging errors are transient; the next scroll retries.
        }
    }

    public func post(id: InstagramMedia.ID) -> InstagramMedia? {
        posts.first { $0.id == id }
    }

    private func fail(with error: Error) {
        if (error as? GraphAPIError)?.isAuthenticationError == true { needsReauthentication = true }
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        phase = .failed(message)
    }
}
