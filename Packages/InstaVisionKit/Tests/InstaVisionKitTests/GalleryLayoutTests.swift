import Testing
import simd
@testable import InstaVisionKit

@Suite struct GalleryLayoutTests {
    @Test func everyFrameSitsOnTheArcFacingTheViewer() {
        let placements = GalleryLayout.placements(count: 16)
        #expect(placements.count == 16)
        for placement in placements {
            let horizontal = SIMD2(placement.position.x, placement.position.z)
            #expect(abs(simd_length(horizontal) - GalleryLayout.radius) < 0.001)
            #expect(placement.position.z < 0, "frames are in front of the viewer")
            // Yaw undoes the angle around the arc, so each plane's normal points back at the origin.
            let angle = atan2(placement.position.x, -placement.position.z)
            #expect(abs(placement.yaw + angle) < 0.001)
        }
    }

    @Test func layoutIsSymmetricAndRowsAreStacked() {
        let placements = GalleryLayout.placements(count: 6)
        #expect(abs(placements.first!.position.x + placements.last!.position.x) < 0.001)
        #expect(placements[0].position.y > placements[1].position.y)
        #expect(GalleryLayout.placements(count: 0).isEmpty)
    }
}
