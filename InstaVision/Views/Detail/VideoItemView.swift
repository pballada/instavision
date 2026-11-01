import AVKit
import SwiftUI

/// Plays a video post, starting when shown and pausing when it scrolls away or the window closes.
struct VideoItemView: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                let player = self.player ?? AVPlayer(url: url)
                self.player = player
                player.play()
            }
            .onDisappear { player?.pause() }
    }
}
