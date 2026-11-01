import AVFoundation
import RealityKit
import SwiftUI
import InstaVisionKit

/// Immersive space that plays Reels on a giant vertical screen with the room dimmed.
struct ReelsTheaterView: View {
    /// Screen height in meters; width follows the video's aspect ratio.
    static let screenHeight: Float = 3.2
    static let screenPosition: SIMD3<Float> = [0, 1.9, -3.4]

    @Environment(AppSession.self) private var session
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @AppStorage("reelsMuted") private var isMuted = false

    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var currentID: InstagramMedia.ID?

    var body: some View {
        RealityView { content, attachments in
            let screen = Entity()
            screen.name = "screen"
            screen.components.set(VideoPlayerComponent(avPlayer: player))
            // VideoPlayerComponent renders a 1 m tall video; scale it up to theater size.
            screen.scale = SIMD3(repeating: Self.screenHeight)
            screen.position = Self.screenPosition
            content.add(screen)

            if let controls = attachments.entity(for: "controls") {
                controls.position = [0, 1.0, -1.6]
                content.add(controls)
            }
        } attachments: {
            Attachment(id: "controls") { controls }
        }
        .preferredSurroundingsEffect(.systemDark)
        .onAppear {
            session.isTheaterOpen = true
            currentID = session.theaterReelID ?? session.reels?.reels.first?.id
        }
        .onDisappear {
            player.pause()
            looper?.disableLooping()
            session.isTheaterOpen = false
        }
        .onChange(of: currentID, initial: true) { _, id in play(id) }
        .onChange(of: isMuted, initial: true) { _, muted in player.isMuted = muted }
    }

    private var store: ReelsStore? { session.reels }

    private var current: InstagramMedia? {
        store?.reels.first { $0.id == currentID }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            Button("Previous", systemImage: "chevron.left") { step(-1) }
                .disabled(neighbour(-1) == nil)
            VStack(alignment: .leading, spacing: 4) {
                Text(current?.caption ?? "Reel")
                    .font(.headline)
                    .lineLimit(2)
                if let likes = current?.likeCount {
                    Label(likes.formatted(.number.notation(.compactName)), systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 320, alignment: .leading)
            Button("Next", systemImage: "chevron.right") { step(1) }
                .disabled(neighbour(1) == nil)
            Button(isMuted ? "Unmute" : "Mute", systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                isMuted.toggle()
            }
            Button("Exit Theater", systemImage: "xmark") {
                Task { await dismissImmersiveSpace() }
            }
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .padding(20)
        .glassBackgroundEffect()
    }

    private func neighbour(_ offset: Int) -> InstagramMedia? {
        guard let currentID else { return nil }
        return store?.reel(after: currentID, offset: offset)
    }

    private func step(_ offset: Int) {
        guard let next = neighbour(offset) else { return }
        currentID = next.id
        session.theaterReelID = next.id
        Task { await store?.loadMoreIfNeeded(after: next) }
    }

    private func play(_ id: InstagramMedia.ID?) {
        looper?.disableLooping()
        player.removeAllItems()
        guard let url = store?.reels.first(where: { $0.id == id })?.mediaURL else { return }
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        player.play()
    }
}
