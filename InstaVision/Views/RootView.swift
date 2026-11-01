import SwiftUI
import InstaVisionKit

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            switch session.state {
            case .launching:
                ProgressView()
            case .signedOut:
                SignInView()
            case .demo, .signedIn:
                if let feed = session.feed {
                    FeedPlaceholderView(feed: feed)
                }
            }
        }
        .task { await session.restore() }
        .onChange(of: session.feed?.needsReauthentication) { _, needsAuth in
            if needsAuth == true { Task { await session.signOut() } }
        }
    }
}

/// Temporary feed view until the grid lands.
private struct FeedPlaceholderView: View {
    let feed: FeedStore

    var body: some View {
        VStack {
            if let profile = feed.profile { Text("@\(profile.username)").font(.title) }
            Text("\(feed.posts.count) posts loaded")
        }
        .task { await feed.loadIfNeeded() }
    }
}
