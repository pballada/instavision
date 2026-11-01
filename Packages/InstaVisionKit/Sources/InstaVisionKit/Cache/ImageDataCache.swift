import CryptoKit
import Foundation

/// Two-level (memory + disk) cache for image bytes.
///
/// Instagram CDN URLs carry signed query parameters that change over time, so entries are keyed by
/// host and path only. In-flight downloads are shared, so a tile and a detail window asking for the
/// same image fetch it once.
public actor ImageDataCache {
    public static let shared = ImageDataCache()

    public typealias Fetch = @Sendable (URL) async throws -> Data

    private let memory = NSCache<NSString, NSData>()
    private let directory: URL?
    private let fetch: Fetch
    private var inFlight: [String: Task<Data, Error>] = [:]

    public init(
        directory: URL? = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Images", isDirectory: true),
        memoryLimit: Int = 150 * 1024 * 1024,
        fetch: @escaping Fetch = { url in
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw GraphAPIError.http(status: http.statusCode)
            }
            return data
        }
    ) {
        self.directory = directory
        self.fetch = fetch
        memory.totalCostLimit = memoryLimit
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    public func data(for url: URL) async throws -> Data {
        let key = Self.key(for: url)
        if let hit = memory.object(forKey: key as NSString) { return hit as Data }
        if let file = fileURL(for: key), let data = try? Data(contentsOf: file) {
            memory.setObject(data as NSData, forKey: key as NSString, cost: data.count)
            return data
        }
        if let task = inFlight[key] { return try await task.value }

        let fetch = self.fetch
        let task = Task { try await fetch(url) }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        let data = try await task.value
        memory.setObject(data as NSData, forKey: key as NSString, cost: data.count)
        if let file = fileURL(for: key) { try? data.write(to: file, options: .atomic) }
        return data
    }

    public func removeAll() {
        memory.removeAllObjects()
        if let directory {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    static func key(for url: URL) -> String {
        let stable = "\(url.host() ?? "")\(url.path())"
        return SHA256.hash(data: Data(stable.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func fileURL(for key: String) -> URL? {
        directory?.appendingPathComponent(key)
    }
}
