import Foundation
import Testing
@testable import InstaVisionKit

private actor Counter {
    var count = 0
    func increment() { count += 1 }
}

@Suite struct ImageDataCacheTests {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    @Test func fetchesOnceThenHitsCache() async throws {
        let counter = Counter()
        let cache = ImageDataCache(directory: directory) { _ in
            await counter.increment()
            return Data("img".utf8)
        }
        let url = URL(string: "https://cdn.example.com/a.jpg?sig=1")!
        _ = try await cache.data(for: url)
        let second = try await cache.data(for: URL(string: "https://cdn.example.com/a.jpg?sig=2")!)
        #expect(second == Data("img".utf8))
        #expect(await counter.count == 1, "signature changes must not bust the cache")
    }

    @Test func survivesOnDisk() async throws {
        let url = URL(string: "https://cdn.example.com/b.jpg")!
        _ = try await ImageDataCache(directory: directory) { _ in Data("disk".utf8) }.data(for: url)
        let fresh = ImageDataCache(directory: directory) { _ in throw URLError(.notConnectedToInternet) }
        #expect(try await fresh.data(for: url) == Data("disk".utf8))
    }

    @Test func sharesInFlightRequests() async throws {
        let counter = Counter()
        let cache = ImageDataCache(directory: nil) { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return Data()
        }
        let url = URL(string: "https://cdn.example.com/c.jpg")!
        async let a = cache.data(for: url)
        async let b = cache.data(for: url)
        _ = try await (a, b)
        #expect(await counter.count == 1)
    }
}
