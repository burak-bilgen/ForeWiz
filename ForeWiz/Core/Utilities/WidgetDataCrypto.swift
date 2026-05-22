import Foundation
import CryptoKit

/// Encrypts/decrypts widget data stored in shared UserDefaults.
/// Uses AES-GCM with a key that can be provided externally (from Keychain/shared container)
/// or derived deterministically from the app group identifier as fallback.
///
/// Architecture:
/// - `WidgetKeyManager` manages the encryption key in the shared app group container
/// - `WidgetDataCrypto` uses that key, falling back to a deterministic key if unavailable
/// - Both main app and widget extension use the same logic via independent copies
public enum WidgetDataCrypto {

    /// Encrypts data with AES-GCM using the provided key, or a deterministic fallback key.
    /// - Parameters:
    ///   - data: Plaintext data to encrypt
    ///   - key: Optional symmetric key. If nil, uses deterministic fallback.
    /// - Returns: Combined sealed box (nonce + ciphertext + tag)
    public static func encrypt(_ data: Data, key: SymmetricKey? = nil) throws -> Data {
        let encryptionKey = key ?? deterministicKey()
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else {
            throw WidgetCryptoError.encryptionFailed
        }
        return combined
    }

    /// Decrypts data with AES-GCM using the provided key, or a deterministic fallback key.
    /// - Parameters:
    ///   - data: Combined sealed box (nonce + ciphertext + tag)
    ///   - key: Optional symmetric key. If nil, uses deterministic fallback.
    /// - Returns: Original plaintext data
    public static func decrypt(_ data: Data, key: SymmetricKey? = nil) throws -> Data {
        let encryptionKey = key ?? deterministicKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }

    /// Deterministic fallback key derived from app group identifier.
    /// Used when no Keychain/shared-container key is available (e.g., first launch).
    public static func deterministicKey() -> SymmetricKey {
        let material = "com.forewiz.widget.encryption.v1.\(AppKeys.appGroupSuiteName)"
        let hash = SHA256.hash(data: Data(material.utf8))
        return SymmetricKey(data: hash)
    }
}

/// Errors that can occur during widget data encryption/decryption.
public enum WidgetCryptoError: Error, LocalizedError {
    case encryptionFailed

    public var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Widget data encryption failed"
        }
    }
}
