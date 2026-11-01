import SwiftUI
import InstaVisionKit

/// Vertical, swipeable Reels player shown in its own 9:16 window.
struct ReelsPlayerView: View {
    let startID: InstagramMedia.ID

    @Environment(AppSession.self) private var session
    @Environment(\.openURL) private var openURL
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @AppStorage("reelsMuted") private var isMuted = false
    @State private var currentID: InstagramMedia.ID?
    @State private var pool = ReelPlayerPool()

    var body: some View {
        if let store = session.reels {
            player(store)
        } else {
            ContentUnavailableView("Sign in to watch Reels", systemImage: "play.rectangle.on.rectangle")
        }
    }

    private func player(_ store: ReelsStore) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(store.reels) { reel in
                    ReelPageView(reel: reel, isActive: reel.id == currentID, isMuted: isMuted, pool: pool)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(reel.id)
                        .task { await store.loadMoreIfNeeded(after: reel) }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentID)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .onAppear { if currentID == nil { currentID = startID } }
        .onChange(of: currentID, initial: true) { _, id in
            if let id { pool.prepare(around: id, in: store.reels) }
        }
        .onChange(of: isMuted) { _, muted in pool.setMuted(muted) }
        .onDisappear { pool.removeAll() }
        .ornament(attachmentAnchor: .scene(.trailing), contentAlignment: .leading) {
            controls(store)
        }
        .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
            if let reel = current(store) { caption(reel) }
        }
    }

    private func current(_ store: ReelsStore) -> InstagramMedia? {
        store.reels.first { $0.id == currentID }
    }

    private func controls(_ store: ReelsStore) -> some View {
        VStack(spacing: 18) {
            Button("Previous", systemImage: "chevron.up") { step(store, by: -1) }
                .disabled(currentID.flatMap { store.reel(after: $0, offset: -1) } == nil)
            Button("Next", systemImage: "chevron.down") { step(store, by: 1) }
                .disabled(currentID.flatMap { store.reel(after: $0, offset: 1) } == nil)

            Divider().frame(width: 32)

            if let reel = current(store) {
                stat(reel.likeCount, systemImage: "heart.fill")
                stat(reel.commentsCount, systemImage: "bubble.right.fill")
            }
            Button(isMuted ? "Unmute" : "Mute", systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                isMuted.toggle()
            }
            Button("Reels Theater", systemImage: "theatermasks.fill") {
                Task { await openTheater() }
            }
            .disabled(currentID == nil || session.isTheaterOpen)
            if let permalink = current(store)?.permalink {
                Button("Open on Instagram", systemImage: "arrow.up.right.square") { openURL(permalink) }
            }
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .padding(14)
        .glassBackgroundEffect()
    }

    @ViewBuilder private func stat(_ value: Int?, systemImage: String) -> some View {
        if let value {
            VStack(spacing: 2) {
                Image(systemName: systemImage).font(.title3)
                Text(value, format: .number.notation(.compactName)).font(.caption)
            }
        }
    }

    private func caption(_ reel: InstagramMedia) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let caption = reel.caption, !caption.isEmpty {
                Text(caption).font(.headline).lineLimit(3)
            }
            if let timestamp = reel.timestamp {
                Text(timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 480, alignment: .leading)
        .glassBackgroundEffect()
    }

    /// Only one immersive space can be open, so the gallery wall closes first.
    private func openTheater() async {
        session.theaterReelID = currentID
        pool.removeAll()
        if session.isGalleryOpen { await dismissImmersiveSpace() }
        _ = await openImmersiveSpace(id: SceneID.theater)
    }

    private func step(_ store: ReelsStore, by offset: Int) {
        guard let currentID, let target = store.reel(after: currentID, offset: offset) else { return }
        withAnimation(.smooth) { self.currentID = target.id }
    }
}
