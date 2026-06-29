import Testing
import Foundation
import CryptoKit
@testable import ForeWiz

@Suite("Widget Data Crypto Tests")
struct WidgetDataCryptoTests {

    @Test("Deterministic key is 256 bits (32 bytes)")
    func deterministicKeySize() {
        let key = WidgetDataCrypto.deterministicKey()
        #expect(key.bitCount == 256)
    }

    @Test("Deterministic key is consistent across calls")
    func deterministicKeyConsistency() {
        let key1 = WidgetDataCrypto.deterministicKey()
        let key2 = WidgetDataCrypto.deterministicKey()
        #expect(key1 == key2)
    }

    @Test("Encrypt then decrypt returns original data (deterministic key)")
    func roundtripDeterministic() throws {
        let original = "Hello, ForeWiz!".data(using: .utf8)!
        let encrypted = try WidgetDataCrypto.encrypt(original)
        let decrypted = try WidgetDataCrypto.decrypt(encrypted)
        #expect(decrypted == original)
    }

    @Test("Encrypt then decrypt returns original data (custom key)")
    func roundtripCustomKey() throws {
        let original = "Widget test data with special chars: 你好 🌤️ 42°C".data(using: .utf8)!
        let key = SymmetricKey(data: try! Data(repeating: 0xAB, count: 32))

        let encrypted = try WidgetDataCrypto.encrypt(original, key: key)
        let decrypted = try WidgetDataCrypto.decrypt(encrypted, key: key)
        #expect(decrypted == original)
    }

    @Test("Encrypt with deterministic key, decrypt with same deterministic key")
    func roundtripDeterministicCrossCall() throws {
        let original = "{\"location\":\"Istanbul\",\"temp\":22.5}".data(using: .utf8)!

        let encrypted = try WidgetDataCrypto.encrypt(original)

        let decrypted = try WidgetDataCrypto.decrypt(encrypted)
        #expect(decrypted == original)
    }

    @Test("Encrypted output is not plaintext (different from input)")
    func notPlaintext() throws {
        let original = "Sensitive data".data(using: .utf8)!
        let encrypted = try WidgetDataCrypto.encrypt(original)
        #expect(encrypted != original)
        #expect(encrypted.count > 0)
    }

    @Test("Encrypted output differs each time (random nonce)")
    func randomNonce() throws {
        let original = "Same data each time".data(using: .utf8)!
        let encrypted1 = try WidgetDataCrypto.encrypt(original)
        let encrypted2 = try WidgetDataCrypto.encrypt(original)

        #expect(encrypted1 != encrypted2)
    }

    @Test("Decrypting corrupted data throws error")
    func corruptedData() throws {
        let corrupted = Data([0x00, 0x01, 0x02, 0x03])
        #expect(throws: (any Error).self) {
            try WidgetDataCrypto.decrypt(corrupted)
        }
    }

    @Test("Decrypting with wrong key throws error")
    func wrongKey() throws {
        let original = "Secret".data(using: .utf8)!
        let correctKey = WidgetDataCrypto.deterministicKey()
        let wrongKey = SymmetricKey(data: try! Data(repeating: 0xFF, count: 32))

        let encrypted = try WidgetDataCrypto.encrypt(original, key: correctKey)
        #expect(throws: (any Error).self) {
            try WidgetDataCrypto.decrypt(encrypted, key: wrongKey)
        }
    }

    @Test("Empty data roundtrip works")
    func emptyData() throws {
        let original = Data()
        let encrypted = try WidgetDataCrypto.encrypt(original)
        let decrypted = try WidgetDataCrypto.decrypt(encrypted)
        #expect(decrypted == original)
    }

    @Test("Large JSON-like data roundtrip")
    func largeDataRoundtrip() throws {

        var items: [[String: Any]] = []
        for i in 0..<50 {
            items.append([
                "locationName": "Istanbul TR-34",
                "currentTemperature": Double.random(in: -5...40),
                "currentConditionSymbol": "cloud.sun.fill",
                "outdoorScore": Int.random(in: 0...100),
                "lastUpdated": Date().timeIntervalSince1970
            ])
        }
        let json = try JSONSerialization.data(withJSONObject: items)
        let encrypted = try WidgetDataCrypto.encrypt(json)
        let decrypted = try WidgetDataCrypto.decrypt(encrypted)
        #expect(decrypted == json)
    }
}
