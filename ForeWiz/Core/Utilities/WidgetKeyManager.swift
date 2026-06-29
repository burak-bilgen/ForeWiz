import Foundation
import CryptoKit
import Security

public enum WidgetKeyManager {

    private static let keyFilename = ".widget-encryption-key-v1"

    private static func keyFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppKeys.appGroupSuiteName)?
            .appendingPathComponent(keyFilename)
    }

    public static func loadOrCreateKey() -> SymmetricKey? {

        if let existing = loadExistingKey() {
            return existing
        }

        return createAndSaveKey()
    }

    private static func loadExistingKey() -> SymmetricKey? {
        guard let url = keyFileURL() else { return nil }
        guard let keyData = try? Data(contentsOf: url), keyData.count == 32 else { return nil }
        return SymmetricKey(data: keyData)
    }

    private static func createAndSaveKey() -> SymmetricKey? {
        guard let url = keyFileURL() else { return nil }

        var keyData = Data(count: 32)
        var randomResult: Int32 = errSecUnimplemented
        keyData.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            randomResult = SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
        }
        guard randomResult == errSecSuccess else { return nil }

        let key = SymmetricKey(data: keyData)

        do {
            try keyData.write(to: url, options: .atomic)

            try (url as NSURL).setResourceValue(
                FileProtectionType.complete,
                forKey: .fileProtectionKey
            )
        } catch {

            return key
        }

        return key
    }

    public static func deleteKey() {
        guard let url = keyFileURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
