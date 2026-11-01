import SwiftUI
import InstaVisionKit

struct RootView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.openWindow) private var openWindow
    @SceneStorage("selectedTab") private var tab = AppTab.reels

    var body: some View {
        Group {
            switch session.state {
            case .launching:
                ProgressView()
            case .signedOut:
                SignInView()
            case .demo, .signedIn:
                if let feed = session.feed, let reels = session.reels {
                    TabView(selection: $tab) {
                        Tab("Reels", systemImage: "play.rectangle.on.rectangle", value: AppTab.reels) {
                            ReelsView(store: reels) { reel in
                                openWindow(id: SceneID.media, value: reel)
                            }
                        }
                        Tab("Posts", systemImage: "square.grid.3x3", value: AppTab.posts) {
                            FeedView(feed: feed) { post in
                                openWindow(id: SceneID.media, value: post)
                            }
                        }
                    }
                }
            }
        }
        .task { await session.restore() }
        .onChange(of: session.feed?.needsReauthentication) { _, needsAuth in
            if needsAuth == true { Task { await session.signOut() } }
        }
    }
}

enum AppTab: String {
    case reels, posts
}
