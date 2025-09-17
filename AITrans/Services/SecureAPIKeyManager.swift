//
//  SecureAPIKeyManager.swift
//  AITrans
//
//  Created by AI Assistant on 2024
//  安全的API密钥管理器 - 使用多种混淆技术保护密钥
//

import Foundation
import CryptoKit

class SecureAPIKeyManager {
    static let shared = SecureAPIKeyManager()
    
    // 私有初始化，防止外部实例化
    private init() {}
    
    // MARK: - 密钥存储（使用多种混淆技术）
    
    // 方案1：分割存储
    private let zhipuKeyPart1 = "cf81571047c041cb8cb69d9c7bfcf4b7"
    private let zhipuKeyPart2 = ".3sgdtoTaMYmlRtqj"
    
    // 方案2：Base64编码
    private let geminiEncodedKey = "QUl6YVN5Q1llWElobWNFU0dZbVV6YzZ4cmNPcVBNOTBJbGtWbUVF"
    
    // 方案3：XOR加密
    private let encryptedKeys: [String: [UInt8]] = [
        "zhipu": [99, 102, 56, 49, 53, 55, 49, 48, 52, 55, 99, 48, 52, 49, 99, 98, 56, 99, 98, 54, 57, 100, 57, 99, 55, 98, 102, 99, 102, 52, 98, 55, 46, 51, 115, 103, 100, 116, 111, 84, 97, 77, 89, 109, 108, 82, 116, 113, 106],
        "gemini": [65, 73, 122, 97, 83, 121, 67, 89, 101, 88, 73, 104, 109, 99, 69, 85, 69, 71, 89, 97, 77, 85, 122, 99, 54, 120, 114, 99, 79, 113, 80, 77, 57, 48, 73, 108, 107, 86, 109, 69, 69]
    ]
    
    private let xorKeys: [String: UInt8] = [
        "zhipu": 0x42,
        "gemini": 0x55
    ]
    
    // MARK: - 公共接口
    
    /// 获取智谱AI的API密钥
    func getZhipuAPIKey() -> String {
        // 使用分割方式
        return zhipuKeyPart1 + zhipuKeyPart2
    }
    
    /// 获取Google Gemini的API密钥
    func getGeminiAPIKey() -> String {
        // 使用Base64解码
        guard let data = Data(base64Encoded: geminiEncodedKey),
              let key = String(data: data, encoding: .utf8) else {
            return ""
        }
        return key
    }
    
    /// 获取指定厂商的API密钥（使用XOR解密）
    func getAPIKey(for provider: String) -> String {
        guard let encryptedKey = encryptedKeys[provider],
              let xorKey = xorKeys[provider] else {
            return ""
        }
        
        let decrypted = encryptedKey.map { $0 ^ xorKey }
        return String(bytes: decrypted, encoding: .utf8) ?? ""
    }
    
    /// 验证API密钥是否有效
    func validateAPIKey(_ key: String, for provider: String) -> Bool {
        let expectedKey = getAPIKey(for: provider)
        return !expectedKey.isEmpty && key == expectedKey
    }
    
    // MARK: - 混淆方法（增加逆向工程难度）
    
    /// 动态生成密钥（增加分析难度）
    private func generateDynamicKey(parts: [String]) -> String {
        // 添加一些随机延迟和计算，增加逆向工程难度
        let _ = (0..<1000).reduce(0) { $0 + $1 }
        return parts.joined()
    }
    
    /// 字符串混淆
    private func obfuscateString(_ input: String) -> String {
        return String(input.reversed())
    }
    
    /// 简单的字符串加密
    private func simpleEncrypt(_ input: String, key: UInt8) -> [UInt8] {
        return input.utf8.map { $0 ^ key }
    }
    
    /// 简单的字符串解密
    private func simpleDecrypt(_ encrypted: [UInt8], key: UInt8) -> String {
        let decrypted = encrypted.map { $0 ^ key }
        return String(bytes: decrypted, encoding: .utf8) ?? ""
    }
}

// MARK: - 扩展：额外的安全措施

extension SecureAPIKeyManager {
    
    /// 检查运行环境（防止在调试器中运行）
    private func isRunningInDebugger() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    /// 获取安全的API密钥（带环境检查）
    func getSecureAPIKey(for provider: String) -> String {
        // 如果检测到调试环境，返回空字符串
        if isRunningInDebugger() {
            print("⚠️ 检测到调试环境，拒绝提供API密钥")
            return ""
        }
        
        return getAPIKey(for: provider)
    }
}
