import SwiftUI
import UIKit
import InstaVisionKit

/// Drop-in replacement for `AsyncImage` backed by `ImageDataCache`.
struct CachedImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else {
            phase = .failure(URLError(.badURL))
            return
        }
        do {
            let data = try await ImageDataCache.shared.data(for: url)
            guard let image = await decode(data) else { throw URLError(.cannotDecodeContentData) }
            phase = .success(Image(uiImage: image))
        } catch is CancellationError {
            // View went away; keep the current phase.
        } catch {
            phase = .failure(error)
        }
    }

    /// Decodes off the main actor so scrolling stays smooth.
    private nonisolated func decode(_ data: Data) async -> UIImage? {
        await UIImage(data: data)?.byPreparingForDisplay()
    }
}

extension CachedImage {
    /// Convenience matching `AsyncImage(url:content:placeholder:)`.
    init<I: View, P: View>(
        url: URL?,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P> {
        self.init(url: url) { phase in
            if case .success(let loaded) = phase { image(loaded) } else { placeholder() }
        }
    }
}
