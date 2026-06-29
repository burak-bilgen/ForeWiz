import Foundation
import CryptoKit

public enum WidgetDataCrypto {

    public static func encrypt(_ data: Data, key: SymmetricKey? = nil) throws -> Data {
        let encryptionKey = key ?? deterministicKey()
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        guard let combined = sealedBox.combined else {
            throw WidgetCryptoError.encryptionFailed
        }
        return combined
    }

    public static func decrypt(_ data: Data, key: SymmetricKey? = nil) throws -> Data {
        let encryptionKey = key ?? deterministicKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }

    public static func deterministicKey() -> SymmetricKey {
        let material = "com.forewiz.widget.encryption.v1.\(AppKeys.appGroupSuiteName)"
        let hash = SHA256.hash(data: Data(material.utf8))
        return SymmetricKey(data: hash)
    }
}

public enum WidgetCryptoError: Error, LocalizedError {
    case encryptionFailed

    public var errorDescription: String? {
        switch self {
        case .encryptionFailed: return "Widget data encryption failed"
        }
    }
}
