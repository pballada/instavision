import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct DemoServiceTests {
    let service = DemoInstagramService(pageSize: 10, totalPosts: 25, latency: .zero)

    @Test func pagesThroughAllPosts() async throws {
        var page = try await service.media(limit: 10)
        var ids = page.data.map(\.id)
        while let next = page.nextURL {
            page = try await service.media(nextPage: next)
            ids += page.data.map(\.id)
        }
        #expect(ids.count == 25)
        #expect(Set(ids).count == 25)
    }

    @Test func halfThePostsAreVerticalReels() async throws {
        let page = try await service.media(limit: 20)
        let reels = page.data.filter(\.isReel)
        #expect(reels.count == 10)
        #expect(reels.allSatisfy { $0.mediaType == .video && $0.mediaURL != nil })
        #expect(reels.allSatisfy { $0.thumbnailURL?.absoluteString.hasSuffix("/1080/1920") == true })
    }

    @Test func includesEveryMediaType() async throws {
        let page = try await service.media(limit: 20)
        let types = Set(page.data.map(\.mediaType))
        #expect(types == [.image, .video, .carouselAlbum])
        #expect(page.data.allSatisfy { $0.previewURL != nil })
    }
}
