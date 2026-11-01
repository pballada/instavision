import Testing
@testable import InstaVisionKit

@Suite struct PreloadWindowTests {
    let ids = ["a", "b", "c", "d", "e"]

    @Test func nearestFirstPreferringAhead() {
        #expect(PreloadWindow.ids(around: "c", in: ids) == ["c", "d", "b"])
        #expect(PreloadWindow.ids(around: "c", in: ids, radius: 2) == ["c", "d", "b", "e", "a"])
    }

    @Test func clampsAtTheEnds() {
        #expect(PreloadWindow.ids(around: "a", in: ids) == ["a", "b"])
        #expect(PreloadWindow.ids(around: "e", in: ids) == ["e", "d"])
    }

    @Test func zeroRadiusAndUnknownIDs() {
        #expect(PreloadWindow.ids(around: "c", in: ids, radius: 0) == ["c"])
        #expect(PreloadWindow.ids(around: "z", in: ids).isEmpty)
    }
}
