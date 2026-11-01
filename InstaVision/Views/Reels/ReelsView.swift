import SwiftUI
import InstaVisionKit

/// The Reels tab: every Reel on the account, newest first.
struct ReelsView: View {
    let store: ReelsStore
    var onSelect: (InstagramMedia) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Reels")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { SettingsButton() }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            Task { await store.refresh() }
                        }
                    }
                }
        }
        .task {
            await store.loadIfNeeded()
            // `--open-reels` launch argument: open the player on the first Reel (screenshots, UI testing).
            if ProcessInfo.processInfo.arguments.contains("--open-reels"), let first = store.reels.first {
                onSelect(first)
            }
        }
    }

    @ViewBuilder private var content: some View {
        let reels = store.reels
        switch store.feed.phase {
        case .idle, .loading:
            ProgressView("Loading Reels…")
        case .failed(let message) where reels.isEmpty:
            ContentUnavailableView {
                Label("Couldn't load Reels", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") { Task { await store.refresh() } }
            }
        default:
            if reels.isEmpty && !store.isFilling {
                ContentUnavailableView(
                    "No Reels yet",
                    systemImage: "play.rectangle.on.rectangle",
                    description: Text("Reels you post on Instagram will show up here.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(reels) { reel in
                            Button { onSelect(reel) } label: { ReelTile(reel: reel) }
                                .buttonStyle(.plain)
                                .task { await store.loadMoreIfNeeded(after: reel) }
                        }
                    }
                    .padding(32)
                    if store.isFilling || store.feed.isLoadingMore {
                        ProgressView().padding(.bottom, 32)
                    }
                }
                .refreshable { await store.refresh() }
            }
        }
    }
}
