import Foundation
import Security

/// Stores the credential as a generic password item in the Keychain.
public actor KeychainCredentialStore: CredentialStore {
    public struct KeychainError: Error, Equatable { public let status: OSStatus }

    private let service: String
    private let account: String
    private var cached: Credential??

    public init(service: String = "com.pballada.instavision", account: String = "instagram") {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    public func load() -> Credential? {
        if let cached { return cached }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let credential = (status == errSecSuccess ? result as? Data : nil)
            .flatMap { try? JSONDecoder().decode(Credential.self, from: $0) }
        cached = .some(credential)
        return credential
    }

    public func save(_ credential: Credential) throws {
        let data = try JSONEncoder().encode(credential)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        var status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(baseQuery.merging(attributes) { $1 } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        cached = .some(credential)
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
        cached = .some(nil)
    }
}
