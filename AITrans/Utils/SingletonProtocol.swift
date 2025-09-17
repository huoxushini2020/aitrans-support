//
//  SingletonProtocol.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation

// MARK: - 单例工具类
class SingletonManager {
    private static var instances: [String: AnyObject] = [:]
    private static let lock = NSLock()
    
    static func getInstance<T: AnyObject>(_ type: T.Type, factory: () -> T) -> T {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        if let instance = instances[key] as? T {
            return instance
        }
        
        let instance = factory()
        instances[key] = instance
        return instance
    }
    
    static func clearInstance<T: AnyObject>(_ type: T.Type) {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        instances.removeValue(forKey: key)
    }
}

// MARK: - 单例宏（简化实现）
func createSingleton<T: AnyObject>(_ type: T.Type, factory: @escaping () -> T) -> T {
    return SingletonManager.getInstance(type, factory: factory)
}
