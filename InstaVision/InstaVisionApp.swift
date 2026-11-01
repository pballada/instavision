import SwiftUI
import InstaVisionKit

@main
struct InstaVisionApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .defaultSize(width: 1100, height: 800)

        WindowGroup(id: SceneID.media, for: InstagramMedia.self) { $post in
            if let post {
                MediaDetailView(post: post)
                    .environment(session)
            }
        }
        .defaultSize(width: 900, height: 900)

        ImmersiveSpace(id: SceneID.gallery) {
            GalleryWallView()
                .environment(session)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

enum SceneID {
    static let media = "media"
    static let gallery = "gallery"
}
