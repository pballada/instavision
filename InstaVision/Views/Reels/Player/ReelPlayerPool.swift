import AVFoundation
import InstaVisionKit

/// Keeps looping players ready for the Reel on screen and its neighbours, so swiping starts
/// playback instantly instead of waiting for the next video to buffer.
@MainActor
final class ReelPlayerPool {
    private struct Entry {
        let player: AVQueuePlayer
        let looper: AVPlayerLooper
    }

    private var entries: [InstagramMedia.ID: Entry] = [:]
    private let radius: Int

    init(radius: Int = 1) {
        self.radius = radius
    }

    /// The looping player for `reel`, created on first use.
    func player(for reel: InstagramMedia) -> AVQueuePlayer? {
        if let entry = entries[reel.id] { return entry.player }
        guard let url = reel.mediaURL else { return nil }
        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 4
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = true
        let looper = AVPlayerLooper(player: player, templateItem: item)
        entries[reel.id] = Entry(player: player, looper: looper)
        return player
    }

    /// Prepares players around `current` and releases the rest.
    func prepare(around current: InstagramMedia.ID, in reels: [InstagramMedia]) {
        let keep = PreloadWindow.ids(around: current, in: reels.map(\.id), radius: radius)
        for id in entries.keys where !keep.contains(id) {
            entries[id]?.player.pause()
            entries[id]?.looper.disableLooping()
            entries[id] = nil
        }
        // Creating the player starts buffering; only the current one plays.
        for id in keep {
            if let reel = reels.first(where: { $0.id == id }) { _ = player(for: reel) }
        }
    }

    func setMuted(_ muted: Bool) {
        for entry in entries.values { entry.player.isMuted = muted }
    }

    func removeAll() {
        for entry in entries.values {
            entry.player.pause()
            entry.looper.disableLooping()
        }
        entries.removeAll()
    }
}
