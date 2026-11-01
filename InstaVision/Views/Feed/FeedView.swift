import SwiftUI
import InstaVisionKit

struct FeedView: View {
    let feed: FeedStore
    var onSelect: (InstagramMedia) -> Void = { _ in }

    @State private var showsSettings = false

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(feed.profile.map { "@\($0.username)" } ?? "InstaVision")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Settings", systemImage: "gearshape") { showsSettings = true }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await feed.refresh() }
                        }
                    }
                }
        }
        .sheet(isPresented: $showsSettings) { SettingsView() }
        .task { await feed.loadIfNeeded() }
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
                        ForEach(feed.posts) { post in
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
