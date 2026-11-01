import SwiftUI
import InstaVisionKit

struct PostTile: View {
    let post: InstagramMedia

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AsyncImage(url: post.previewURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure: Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary)
                    default: ProgressView()
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Image(systemName: badge)
                        .font(.title3)
                        .padding(10)
                        .shadow(radius: 4)
                        .foregroundStyle(.white)
                }
            }
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 16))
            .contentShape(.hoverEffect, .rect(cornerRadius: 16))
            .hoverEffect()
            .accessibilityLabel(post.caption ?? "Post")
    }

    private var badge: String? {
        switch post.mediaType {
        case .image: nil
        case .video: "play.fill"
        case .carouselAlbum: "square.on.square.fill"
        }
    }
}
