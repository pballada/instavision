import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct ReelDetectionTests {
    let decoder = GraphDecoder.make()

    @Test func detectsReels() throws {
        let json = #"""
        {"data":[
          {"id":"r","media_type":"VIDEO","media_product_type":"REELS","is_shared_to_feed":true,
           "media_url":"https://example.com/r.mp4","thumbnail_url":"https://example.com/r.jpg"},
          {"id":"v","media_type":"VIDEO","media_product_type":"FEED","media_url":"https://example.com/v.mp4"},
          {"id":"i","media_type":"IMAGE","media_url":"https://example.com/i.jpg"}
        ]}
        """#
        let page = try decoder.decode(Page<InstagramMedia>.self, from: Data(json.utf8))
        #expect(page.data.map(\.isReel) == [true, false, false])
        #expect(page.data[0].isSharedToFeed == true)
        #expect(page.data[2].productType == nil)
    }

    @Test func unknownProductTypeDoesNotFail() throws {
        let json = #"{"id":"x","media_type":"VIDEO","media_product_type":"SOMETHING_NEW"}"#
        let media = try decoder.decode(InstagramMedia.self, from: Data(json.utf8))
        #expect(media.productType == .unknown)
        #expect(!media.isReel)
    }

    @Test func requestsReelFields() {
        #expect(InstagramMedia.fields.contains("media_product_type"))
        #expect(InstagramMedia.fields.contains("is_shared_to_feed"))
    }

    @Test func roundTripsProductType() throws {
        let reel = InstagramMedia(id: "r", mediaType: .video, productType: .reels, isSharedToFeed: false)
        let decoded = try decoder.decode(InstagramMedia.self, from: JSONEncoder().encode(reel))
        #expect(decoded == reel)
    }
}
