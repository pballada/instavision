import SwiftUI
import InstaVisionKit

/// A 9:16 Reel cover with its caption and like count over a gradient, as on Instagram.
struct ReelTile: View {
    let reel: InstagramMedia

    var body: some View {
        Color.clear
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .overlay {
                CachedImage(url: reel.previewURL) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .failure: Image(systemName: "film").font(.largeTitle).foregroundStyle(.secondary)
                    default: ProgressView()
                    }
                }
            }
            .overlay { LinearGradient(colors: [.clear, .clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom) }
            .overlay(alignment: .center) {
                Image(systemName: "play.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 6)
            }
            .overlay(alignment: .bottomLeading) { details }
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 20))
            .contentShape(.hoverEffect, .rect(cornerRadius: 20))
            .hoverEffect(.highlight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(reel.caption ?? "Reel")
            .accessibilityAddTraits(.isButton)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let caption = reel.caption, !caption.isEmpty {
                Text(caption)
                    .font(.callout.weight(.semibold))
                    .lineLimit(2)
            }
            if let likes = reel.likeCount {
                Label(likes.formatted(.number.notation(.compactName)), systemImage: "heart.fill")
                    .font(.caption.weight(.medium))
                    .opacity(0.9)
            }
        }
        .foregroundStyle(.white)
        .shadow(radius: 3)
        .padding(14)
    }
}
