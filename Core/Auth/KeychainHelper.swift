import Foundation
import KeychainAccess

enum KeychainHelper {
    private static let keychain = Keychain(service: "com.eksilik.app")

    static func save(key: String, value: String) {
        keychain[key] = value
    }

    static func get(key: String) -> String? {
        keychain[key]
    }

    static func delete(key: String) {
        try? keychain.remove(key)
    }
}
