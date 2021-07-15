//
//  KspUserStorage.swift
//  kacper WatchKit Extension
//
//  Created by Kacper Serewiś on 15/07/2021.
//

import Foundation


enum KspUserStorageKey : String {
    case SavedToothbrush
}

class KspUserStorage {
    static func saveStringToStorage(storageKey: KspUserStorageKey, value: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: storageKey.rawValue)
    }
    
    static func getStringFromStorage(storageKey: KspUserStorageKey) -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: storageKey.rawValue)
    }
    
    static func removeFromStorage(storageKey: KspUserStorageKey) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: storageKey.rawValue)
    }
}
