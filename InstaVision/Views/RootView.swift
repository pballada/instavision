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
                    FeedView(feed: feed)
                }
            }
        }
        .task { await session.restore() }
        .onChange(of: session.feed?.needsReauthentication) { _, needsAuth in
            if needsAuth == true { Task { await session.signOut() } }
        }
    }
}
