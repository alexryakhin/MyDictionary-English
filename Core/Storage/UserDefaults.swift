//
//  UserDefaults.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/2/24.
//

import Foundation

protocol UserDefaultsServiceInterface: AnyObject {

    func save(string: String?, forKey key: String)
    func save(bool: Bool, forKey key: String)
    func loadString(forKey key: String) -> String?
    func loadBool(forKey key: String) -> Bool
}

final class UserDefaultsService: NSObject, UserDefaultsServiceInterface {

    func save(string: String?, forKey key: String) {
        UserDefaults.standard.set(string, forKey: key)
    }

    func save(bool: Bool, forKey key: String) {
        UserDefaults.standard.set(bool, forKey: key)
    }

    func loadString(forKey key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    func loadBool(forKey key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }
}
