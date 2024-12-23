//
//  UserDefault+Helper.swift
//  ScreenZ
//
//  Created by 周源坤 on 12/19/24.
//
import Foundation

enum UserSettingsKey: String {
    case isInitialized
    case currentVideoID
    case enableAutoSetUp
    case enableBlackMenuBar
}

extension UserDefaults {
    func set(currentVideoID: String) {
        self.set(currentVideoID, forKey: UserSettingsKey.currentVideoID.rawValue)
    }
    
    var currentVideoID: String? {
        return self.string(forKey: UserSettingsKey.currentVideoID.rawValue)
    }
    
    func enableAutoSetUp(status: Bool) {
        self.set(status, forKey: UserSettingsKey.enableAutoSetUp.rawValue)
    }
    
    var autoSetUp: Bool {
        return self.bool(forKey: UserSettingsKey.enableAutoSetUp.rawValue)
    }
    
    func enableBlackMenuBar(status: Bool) {
        self.set(status, forKey: UserSettingsKey.enableBlackMenuBar.rawValue)
    }
    
    var blackMenuBar: Bool {
        return self.bool(forKey: UserSettingsKey.enableBlackMenuBar.rawValue)
    }
    
    func initialize(status: Bool) {
        self.set(status, forKey: UserSettingsKey.isInitialized.rawValue)
    }
    
    var isInitialized: Bool {
        return self.bool(forKey: UserSettingsKey.isInitialized.rawValue)
    }
    
    
}

