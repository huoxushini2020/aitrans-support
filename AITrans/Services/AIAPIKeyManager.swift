//
//  AIAPIKeyManager.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation
import CryptoKit

// MARK: - AI API密钥管理器
class AIAPIKeyManager {
    static let shared = AIAPIKeyManager()
    
    private var apiKeys: [String: AIProviderConfig] = [:]
    private let secureKeyManager = SecureAPIKeyManager.shared
    private let encryptionKey = "AITransSecretKey2024" // 实际项目中应该使用更安全的密钥管理
    
    private init() {
        loadAPIKeys()
    }
    
    // MARK: - 数据结构
    struct AIProviderConfig: Codable {
        let name: String
        let apiKey: String
        let apiUrl: String
        let model: String
        let enabled: Bool
    }
    
    // MARK: - 加载API密钥
    private func loadAPIKeys() {
        // 使用安全密钥管理器加载密钥
        loadSecureAPIKeys()
        
        // 备用：从配置文件加载（如果安全密钥加载失败）
        loadFallbackAPIKeys()
    }
    
    // MARK: - 加载安全密钥
    private func loadSecureAPIKeys() {
        // 智谱AI配置
        let zhipuConfig = AIProviderConfig(
            name: "智谱AI",
            apiKey: secureKeyManager.getZhipuAPIKey(),
            apiUrl: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            model: "glm-4",
            enabled: true
        )
        apiKeys["zhipu"] = zhipuConfig
        
        // Google Gemini配置
        let geminiConfig = AIProviderConfig(
            name: "Google Gemini 2.5 Flash",
            apiKey: secureKeyManager.getGeminiAPIKey(),
            apiUrl: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent",
            model: "gemini-2.0-flash-exp",
            enabled: true
        )
        apiKeys["gemini"] = geminiConfig
        
        print("✅ 安全API密钥加载完成")
    }
    
    // MARK: - 备用密钥加载
    private func loadFallbackAPIKeys() {
        guard let url = Bundle.main.url(forResource: "ai_api_keys", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ 无法加载备用API密钥配置文件")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let providers = json?["ai_providers"] as? [String: [String: Any]] else {
                print("⚠️ 备用API密钥配置文件格式错误")
                return
            }
            
            for (key, provider) in providers {
                // 只加载安全密钥管理器中没有的配置
                if apiKeys[key] == nil {
                    if let name = provider["name"] as? String,
                       let apiKey = provider["api_key"] as? String,
                       let apiUrl = provider["api_url"] as? String,
                       let model = provider["model"] as? String,
                       let enabled = provider["enabled"] as? Bool {
                        
                        let config = AIProviderConfig(
                            name: name,
                            apiKey: apiKey,
                            apiUrl: apiUrl,
                            model: model,
                            enabled: enabled
                        )
                        apiKeys[key] = config
                    }
                }
            }
        } catch {
            print("⚠️ 解析备用API密钥配置文件失败: \(error)")
        }
    }
    
    // MARK: - 获取API密钥
    func getAPIKey(for provider: String) -> String? {
        return apiKeys[provider]?.apiKey
    }
    
    // MARK: - 获取API配置
    func getAPIConfig(for provider: String) -> AIProviderConfig? {
        return apiKeys[provider]
    }
    
    // MARK: - 获取所有启用的厂商
    func getEnabledProviders() -> [AIProviderConfig] {
        return apiKeys.values.filter { $0.enabled }
    }
    
    // MARK: - 获取厂商名称列表
    func getProviderNames() -> [String] {
        return apiKeys.values.map { $0.name }
    }
    
    // MARK: - 根据名称获取厂商配置
    func getProviderConfig(by name: String) -> AIProviderConfig? {
        return apiKeys.values.first { $0.name == name }
    }
    
    // MARK: - 简单的加密/解密（实际项目中应使用更安全的方法）
    private func encrypt(_ text: String) -> String {
        // 这里使用简单的Base64编码作为示例
        // 实际项目中应该使用AES等强加密算法
        guard let data = text.data(using: .utf8) else { return text }
        return data.base64EncodedString()
    }
    
    private func decrypt(_ encryptedText: String) -> String {
        // 这里使用简单的Base64解码作为示例
        // 实际项目中应该使用AES等强加密算法
        guard let data = Data(base64Encoded: encryptedText),
              let decrypted = String(data: data, encoding: .utf8) else {
            return encryptedText
        }
        return decrypted
    }
    
    // MARK: - 验证API密钥
    func validateAPIKey(for provider: String) -> Bool {
        guard let config = apiKeys[provider] else { return false }
        return !config.apiKey.isEmpty && config.enabled
    }
}
