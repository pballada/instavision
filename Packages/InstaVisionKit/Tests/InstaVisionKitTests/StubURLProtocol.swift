import Foundation

/// Intercepts requests made through a session created by `StubURLProtocol.makeSession(_:)`.
/// Each session gets its own handler and request log, so suites can run in parallel.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) -> (Int, Data)

    final class Stub: @unchecked Sendable {
        let session: URLSession
        private let lock = NSLock()
        private var _requests: [URLRequest] = []
        var requests: [URLRequest] { lock.withLock { _requests } }
        fileprivate let handler: Handler

        fileprivate init(session: URLSession, handler: @escaping Handler) {
            self.session = session
            self.handler = handler
        }
        fileprivate func record(_ request: URLRequest) { lock.withLock { _requests.append(request) } }
    }

    private static let header = "X-Stub-ID"
    private static let lock = NSLock()
    nonisolated(unsafe) private static var stubs: [String: Stub] = [:]

    static func makeSession(_ handler: @escaping Handler = { _ in (500, Data()) }) -> Stub {
        let id = UUID().uuidString
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        config.httpAdditionalHeaders = [header: id]
        let stub = Stub(session: URLSession(configuration: config), handler: handler)
        lock.withLock { stubs[id] = stub }
        return stub
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let id = request.value(forHTTPHeaderField: Self.header) ?? ""
        let stub = Self.lock.withLock { Self.stubs[id] }
        stub?.record(request)
        let (status, data) = stub?.handler(request) ?? (500, Data())
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
