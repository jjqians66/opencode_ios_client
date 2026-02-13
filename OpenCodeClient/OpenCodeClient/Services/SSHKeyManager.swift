//
//  SSHKeyManager.swift
//  OpenCodeClient
//

import Foundation
import Security
import CryptoKit

enum SSHKeyManager {
    private static let privateKeyTag = "com.opencode.ssh.privateKey"
    private static let publicKeyKey = "sshPublicKey"
    
    static func generateKeyPair() throws -> (privateKey: Data, publicKey: String) {
        let privateKey = P256.Signing.PrivateKey()
        
        let privateKeyData = privateKey.rawRepresentation
        let publicKeyData = privateKey.publicKey.rawRepresentation
        
        let publicKeyBase64 = publicKeyData.base64EncodedString()
        let publicKeyOpenSSH = "ssh-ed25519 \(publicKeyBase64) opencode-ios"
        
        return (privateKeyData, publicKeyOpenSSH)
    }
    
    static func savePrivateKey(_ key: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: privateKeyTag,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadPrivateKey() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: privateKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else { return nil }
        return data
    }
    
    static func savePublicKey(_ publicKey: String) {
        UserDefaults.standard.set(publicKey, forKey: publicKeyKey)
    }
    
    static func getPublicKey() -> String? {
        UserDefaults.standard.string(forKey: publicKeyKey)
    }
    
    static func deleteKeyPair() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: privateKeyTag
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: publicKeyKey)
    }
    
    static func hasKeyPair() -> Bool {
        loadPrivateKey() != nil && getPublicKey() != nil
    }
    
    static func ensureKeyPair() throws -> String {
        if let existing = getPublicKey() {
            return existing
        }
        
        let (privateKey, publicKey) = try generateKeyPair()
        savePrivateKey(privateKey)
        savePublicKey(publicKey)
        return publicKey
    }
    
    static func rotateKey() throws -> String {
        deleteKeyPair()
        return try ensureKeyPair()
    }
}
