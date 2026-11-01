import SwiftUI
import InstaVisionKit

/// A single post in its own window, with details in an ornament below it.
struct MediaDetailView: View {
    let post: InstagramMedia
    @Environment(\.openURL) private var openURL

    var body: some View {
        CarouselView(items: post.items)
            .ornament(attachmentAnchor: .scene(.bottom), contentAlignment: .top) {
                details
                    .padding(24)
                    .frame(maxWidth: 640, alignment: .leading)
                    .glassBackgroundEffect()
            }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let caption = post.caption, !caption.isEmpty {
                Text(caption).font(.title3).lineLimit(4)
            }
            HStack(spacing: 20) {
                if let likes = post.likeCount {
                    Label(likes.formatted(.number.notation(.compactName)), systemImage: "heart.fill")
                }
                if let comments = post.commentsCount {
                    Label(comments.formatted(.number.notation(.compactName)), systemImage: "bubble.left.fill")
                }
                if let timestamp = post.timestamp {
                    Text(timestamp, format: .dateTime.day().month(.wide).year())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let permalink = post.permalink {
                    Button("Open on Instagram", systemImage: "arrow.up.right.square") { openURL(permalink) }
                }
            }
            .font(.callout)
        }
    }
}

/// Shows one image or video filling the window.
struct MediaItemView: View {
    let item: InstagramMedia

    var body: some View {
        Group {
            if item.mediaType == .video, let url = item.mediaURL {
                VideoItemView(url: url)
            } else {
                AsyncImage(url: item.previewURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFit()
                    case .failure: ContentUnavailableView("Couldn't load this post", systemImage: "photo")
                    default: ProgressView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
