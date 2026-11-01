import Foundation

/// Errors surfaced by the Graph API client.
public enum GraphAPIError: Error, Equatable, Sendable, LocalizedError {
    /// The API returned an error payload, e.g. `{"error":{"message":"...","code":190}}`.
    case api(message: String, code: Int, subcode: Int?)
    case http(status: Int)
    case invalidResponse
    case missingToken

    /// Code 190 means the access token is invalid or expired.
    public var isAuthenticationError: Bool {
        switch self {
        case .api(_, let code, _): code == 190 || code == 102
        case .http(let status): status == 401
        case .missingToken: true
        case .invalidResponse: false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .api(let message, _, _): message
        case .http(let status): "The server responded with status \(status)."
        case .invalidResponse: "The server response could not be read."
        case .missingToken: "You're not signed in."
        }
    }

    struct Envelope: Decodable {
        struct Body: Decodable {
            let message: String
            let code: Int
            let error_subcode: Int?
        }
        let error: Body
    }
}
