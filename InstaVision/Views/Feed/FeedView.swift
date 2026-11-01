import SwiftUI
import InstaVisionKit

struct FeedView: View {
    let feed: FeedStore
    var onSelect: (InstagramMedia) -> Void = { _ in }

    @Environment(AppSession.self) private var session
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    /// The profile grid: posts plus Reels that were shared to the feed, like on Instagram.
    private var gridPosts: [InstagramMedia] {
        feed.posts.filter { !$0.isReel || $0.isSharedToFeed != false }
    }

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(feed.profile.map { "@\($0.username)" } ?? "InstaVision")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { SettingsButton() }
                    ToolbarItem(placement: .primaryAction) {
                        Button(session.isGalleryOpen ? "Close Gallery" : "Gallery Wall",
                               systemImage: session.isGalleryOpen ? "xmark.circle" : "rectangle.3.group") {
                            Task { await toggleGallery() }
                        }
                        .disabled(feed.posts.isEmpty)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await feed.refresh() }
                        }
                    }
                }
        }
        .task { await feed.loadIfNeeded() }
    }

    private func toggleGallery() async {
        if session.isGalleryOpen {
            await dismissImmersiveSpace()
        } else {
            // Only one immersive space can be open, so Reels Theater closes first.
            if session.isTheaterOpen { await dismissImmersiveSpace() }
            _ = await openImmersiveSpace(id: SceneID.gallery)
        }
    }

    @ViewBuilder private var content: some View {
        switch feed.phase {
        case .idle, .loading:
            ProgressView("Loading your feed…")
        case .failed(let message) where feed.posts.isEmpty:
            ContentUnavailableView {
                Label("Couldn't load your feed", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await feed.refresh() } }
            }
        default:
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if let profile = feed.profile {
                        ProfileHeaderView(profile: profile)
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(gridPosts) { post in
                            Button { onSelect(post) } label: { PostTile(post: post) }
                                .buttonStyle(.plain)
                                .task { await feed.loadMoreIfNeeded(after: post) }
                        }
                    }
                    if feed.isLoadingMore {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }
                .padding(32)
            }
            .refreshable { await feed.refresh() }
        }
    }
}
