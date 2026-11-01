import AVFoundation
import SwiftUI
import InstaVisionKit

/// One full-height Reel. Plays while it is the active page; looping is handled by the pool's looper.
struct ReelPageView: View {
    let reel: InstagramMedia
    let isActive: Bool
    let isMuted: Bool
    let pool: ReelPlayerPool

    @State private var player: AVQueuePlayer?
    @State private var isPaused = false

    var body: some View {
        ZStack {
            CachedImage(url: reel.previewURL) { phase in
                if case .success(let image) = phase { image.resizable().scaledToFill() } else { Color.black }
            }
            PlayerLayerView(player: player)
            if isPaused {
                Image(systemName: "play.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipped()
        .contentShape(.rect)
        .onTapGesture { togglePause() }
        .accessibilityLabel(reel.caption ?? "Reel")
        .accessibilityHint("Double tap to pause or play")
        .onChange(of: isActive, initial: true) { _, active in active ? start() : stop() }
        .onChange(of: isMuted) { _, muted in player?.isMuted = muted }
        .onAppear { player = pool.player(for: reel) }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func start() {
        // Always ask the pool: it may have evicted and recreated this Reel's player.
        let player = pool.player(for: reel)
        self.player = player
        player?.isMuted = isMuted
        isPaused = false
        player?.play()
    }

    private func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPaused = false
    }

    private func togglePause() {
        guard let player else { return }
        withAnimation(.snappy) { isPaused.toggle() }
        isPaused ? player.pause() : player.play()
    }
}
