import Foundation
import CryptoKit
import Security

/// Manages the encryption key used for widget data encryption.
///
/// Strategy:
/// 1. On first call, generates a random 256-bit AES key and stores it in the shared
///    app group container (`group.forewiz`) as a file with `NSFileProtectionComplete`.
/// 2. Both the main app and widget extension can read this file since they share
///    the same app group container.
/// 3. If the key file doesn't exist (first launch, or after data reset), creates a new one.
/// 4. If the key file can't be read/written, returns nil so callers can fall back
///    to the deterministic key (graceful degradation).
///
/// This is more secure than a deterministic key because:
/// - The key is randomly generated, not derivable from public information
/// - The key is stored in the shared container with file protection encryption
/// - Compromising the UserDefaults plist alone is insufficient to decrypt the data
public enum WidgetKeyManager {

    private static let keyFilename = ".widget-encryption-key-v1"

    /// Returns the URL of the encryption key file in the shared app group container.
    private static func keyFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppKeys.appGroupSuiteName)?
            .appendingPathComponent(keyFilename)
    }

    /// Loads or creates the encryption key.
    /// - Returns: A 256-bit AES symmetric key, or nil if unavailable (fallback to deterministic key).
    public static func loadOrCreateKey() -> SymmetricKey? {
        // Try to load existing key
        if let existing = loadExistingKey() {
            return existing
        }
        // Create a new key and save it
        return createAndSaveKey()
    }

    /// Loads an existing encryption key from the shared container.
    private static func loadExistingKey() -> SymmetricKey? {
        guard let url = keyFileURL() else { return nil }
        guard let keyData = try? Data(contentsOf: url), keyData.count == 32 else { return nil }
        return SymmetricKey(data: keyData)
    }

    /// Generates a new random 256-bit key and saves it to the shared container.
    private static func createAndSaveKey() -> SymmetricKey? {
        guard let url = keyFileURL() else { return nil }

        // Generate 32 random bytes (256 bits)
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        guard result == errSecSuccess else { return nil }

        let key = SymmetricKey(data: keyData)

        // Write to shared container with file protection
        do {
            try keyData.write(to: url, options: .atomic)
            // Apply NSFileProtectionComplete on the key file
            try (url as NSURL).setResourceValue(
                FileProtectionType.complete,
                forKey: .fileProtectionKey
            )
        } catch {
            // If we can't save, still return the key for this session
            // The next session will generate a new key (old encrypted data becomes unreadable)
            return key
        }

        return key
    }

    /// Deletes the encryption key (for testing or reset).
    public static func deleteKey() {
        guard let url = keyFileURL() else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
