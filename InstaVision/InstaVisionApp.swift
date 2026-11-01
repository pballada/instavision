import SwiftUI

@main
struct InstaVisionApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .defaultSize(width: 1100, height: 800)
    }
}
