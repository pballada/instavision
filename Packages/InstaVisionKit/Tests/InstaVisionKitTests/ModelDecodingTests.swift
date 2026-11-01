import Foundation
import Testing
@testable import InstaVisionKit

@Suite struct ModelDecodingTests {
    let decoder = GraphDecoder.make()

    @Test func decodesProfile() throws {
        let json = #"""
        {"id":"1789","username":"pau","account_type":"MEDIA_CREATOR","media_count":42,
         "followers_count":1200,"profile_picture_url":"https://example.com/p.jpg"}
        """#
        let profile = try decoder.decode(InstagramProfile.self, from: Data(json.utf8))
        #expect(profile.username == "pau")
        #expect(profile.accountType == .mediaCreator)
        #expect(profile.mediaCount == 42)
        #expect(profile.profilePictureURL?.absoluteString == "https://example.com/p.jpg")
    }

    @Test func unknownAccountTypeDoesNotFail() throws {
        let json = #"{"id":"1","username":"x","account_type":"SOMETHING_NEW"}"#
        let profile = try decoder.decode(InstagramProfile.self, from: Data(json.utf8))
        #expect(profile.accountType == .unknown)
    }

    @Test func decodesMediaPageWithCarousel() throws {
        let json = #"""
        {"data":[
          {"id":"a","media_type":"IMAGE","media_url":"https://example.com/a.jpg","timestamp":"2026-08-31T18:10:00+0000","caption":"hi"},
          {"id":"b","media_type":"VIDEO","media_url":"https://example.com/b.mp4","thumbnail_url":"https://example.com/b.jpg"},
          {"id":"c","media_type":"CAROUSEL_ALBUM","children":{"data":[
            {"id":"c1","media_type":"IMAGE","media_url":"https://example.com/c1.jpg"},
            {"id":"c2","media_type":"VIDEO","media_url":"https://example.com/c2.mp4","thumbnail_url":"https://example.com/c2.jpg"}
          ]}}
        ],
        "paging":{"cursors":{"before":"B","after":"A"},"next":"https://graph.instagram.com/v23.0/me/media?after=A"}}
        """#
        let page = try decoder.decode(Page<InstagramMedia>.self, from: Data(json.utf8))
        #expect(page.data.count == 3)
        #expect(page.nextURL != nil)
        #expect(page.data[0].timestamp == Date(timeIntervalSince1970: 1_788_199_800))
        #expect(page.data[1].previewURL?.lastPathComponent == "b.jpg")
        #expect(page.data[2].items.map(\.id) == ["c1", "c2"])
        #expect(page.data[2].previewURL?.lastPathComponent == "c1.jpg")
    }

    @Test func roundTripsMedia() throws {
        let media = InstagramMedia(id: "x", mediaType: .carouselAlbum, children: [
            InstagramMedia(id: "y", mediaType: .image, mediaURL: URL(string: "https://example.com/y.jpg")),
        ])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoded = try decoder.decode(InstagramMedia.self, from: encoder.encode(media))
        #expect(decoded == media)
    }
}
