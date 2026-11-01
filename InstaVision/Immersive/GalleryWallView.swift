import RealityKit
import SwiftUI
import UIKit
import InstaVisionKit

/// Immersive space that hangs recent photos on a curved wall around the viewer.
/// Look at a photo and pinch to open it in a window.
struct GalleryWallView: View {
    static let maxPhotos = 16

    @Environment(AppSession.self) private var session
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        RealityView { content in
            let root = Entity()
            root.name = "gallery"
            content.add(root)
            await populate(root)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let post = session.feed?.post(id: value.entity.name) {
                        openWindow(id: SceneID.media, value: post)
                    }
                }
        )
        .onAppear { session.isGalleryOpen = true }
        .onDisappear { session.isGalleryOpen = false }
    }

    private var posts: [InstagramMedia] {
        Array((session.feed?.posts ?? []).filter { $0.previewURL != nil }.prefix(Self.maxPhotos))
    }

    private func populate(_ root: Entity) async {
        let posts = self.posts
        let placements = GalleryLayout.placements(count: posts.count)
        let images = await loadImages(for: posts)

        for (index, post) in posts.enumerated() {
            guard let cgImage = images[post.id], let frame = await makeFrame(for: post, image: cgImage) else { continue }
            let placement = placements[index]
            frame.position = placement.position
            frame.orientation = simd_quatf(angle: placement.yaw, axis: [0, 1, 0])
            root.addChild(frame)
            // Reveal frames one after another.
            try? await Task.sleep(for: .milliseconds(60))
        }
    }

    private func loadImages(for posts: [InstagramMedia]) async -> [String: CGImage] {
        await withTaskGroup(of: (String, Data?).self) { group in
            for post in posts {
                guard let url = post.previewURL else { continue }
                group.addTask { (post.id, try? await ImageDataCache.shared.data(for: url)) }
            }
            var images: [String: CGImage] = [:]
            for await (id, data) in group {
                if let data, let image = UIImage(data: data)?.cgImage { images[id] = image }
            }
            return images
        }
    }

    private func makeFrame(for post: InstagramMedia, image: CGImage) async -> Entity? {
        guard let texture = try? await TextureResource(image: image, options: .init(semantic: .color)) else { return nil }
        let size = GalleryLayout.frameSize
        let aspect = Float(image.width) / Float(max(image.height, 1))
        let width = aspect >= 1 ? size : size * aspect
        let height = aspect >= 1 ? size / aspect : size

        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        let photo = ModelEntity(
            mesh: .generatePlane(width: width, height: height, cornerRadius: 0.02),
            materials: [material]
        )
        photo.name = post.id
        photo.components.set(InputTargetComponent())
        photo.components.set(CollisionComponent(shapes: [.generateBox(width: width, height: height, depth: 0.01)]))
        photo.components.set(HoverEffectComponent())
        return photo
    }
}
