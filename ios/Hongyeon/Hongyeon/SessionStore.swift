//
//  SessionStore.swift
//  Hongyeon
//
//  Created by Sangha Jeon on 9/8/26.
//

import Foundation
import KeychainAccess

enum SessionStore {
    private static let keychain = Keychain(service: "com.sanghajeon.Hongyeon")
    private static let key = "sessionToken"

    static func save(_ token: String) {
        keychain[key] = token
    }

    static func load() -> String? {
        keychain[key]
    }

    static func clear() {
        keychain[key] = nil
    }
}
