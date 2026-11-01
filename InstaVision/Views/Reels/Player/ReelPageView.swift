import AVFoundation
import SwiftUI
import InstaVisionKit

/// One full-height Reel. Plays while it is the active page and loops.
struct ReelPageView: View {
    let reel: InstagramMedia
    let isActive: Bool
    let isMuted: Bool

    @State private var player: AVPlayer?
    @State private var isPaused = false
    @State private var loopObserver: NSObjectProtocol?

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
        .onDisappear(perform: tearDown)
    }

    private func start() {
        guard let url = reel.mediaURL else { return }
        let player = self.player ?? AVPlayer(url: url)
        player.isMuted = isMuted
        if loopObserver == nil {
            loopObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification, object: player.currentItem, queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        self.player = player
        isPaused = false
        player.play()
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

    private func tearDown() {
        player?.pause()
        if let loopObserver { NotificationCenter.default.removeObserver(loopObserver) }
        loopObserver = nil
        player = nil
    }
}
