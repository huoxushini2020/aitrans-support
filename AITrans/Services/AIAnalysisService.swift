//
//  AIAnalysisService.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation

// MARK: - AI分析服务
class AIAnalysisService {
    
    // MARK: - 单例
    static let shared = AIAnalysisService()
    
    // MARK: - 配置
    private let configManager = AIPromptConfigManager.shared
    private let apiKeyManager = AIAPIKeyManager.shared
    private var currentProvider = "zhipu_ai" // 默认使用智谱AI
    
    // MARK: - 缓存机制
    private var analysisCache: [String: String] = [:]
    private let maxCacheSize = 50 // 最大缓存条目数
    
    // MARK: - 私有初始化
    private init() {
        setupNotificationObservers()
        // 强制重新加载配置，确保使用最新的JSON文件
        configManager.forceReloadConfig()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 通知监听设置
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAIProviderChanged(_:)),
            name: NSNotification.Name("AIProviderChanged"),
            object: nil
        )
    }
    
    @objc private func handleAIProviderChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let config = userInfo["config"] as? AIAPIKeyManager.AIProviderConfig else {
            print("❌ AI分析服务：无法获取厂商配置")
            return
        }
        
        // 根据配置名称找到对应的厂商key
        let providerKey = getProviderKey(by: config.name)
        if let key = providerKey {
            setCurrentProvider(key)
            print("✅ AI分析服务：已通过通知切换到 \(config.name) (\(key))")
        } else {
            print("❌ AI分析服务：无法找到厂商key - \(config.name)")
        }
    }
    
    // MARK: - 分析句子
    func analyzeSentence(_ sentence: String, targetLanguage: String = "zh", completion: @escaping (Result<String, Error>) -> Void) {
        analyzeContent(sentence, isWordSelected: false, targetLanguage: targetLanguage, completion: completion)
    }
    
    // MARK: - 分析单词
    func analyzeWord(_ word: String, targetLanguage: String = "zh", completion: @escaping (Result<String, Error>) -> Void) {
        analyzeContent(word, isWordSelected: true, targetLanguage: targetLanguage, completion: completion)
    }
    
    // MARK: - 智能分析内容
    func analyzeContent(_ content: String, isWordSelected: Bool, targetLanguage: String = "zh", completion: @escaping (Result<String, Error>) -> Void) {
        let _ = isWordSelected ? "单词" : "句子"
        
        // 检查缓存（使用内容+类型+提示词版本作为缓存键）
        let promptVersion = configManager.getPromptVersion()
        let cacheKey = "\(isWordSelected ? "word" : "sentence"):\(promptVersion):\(content)"
        if let cachedResult = analysisCache[cacheKey] {
            // 缓存命中，立即返回结果
            DispatchQueue.main.async {
                completion(.success(cachedResult))
            }
            return
        }
        
        
        // 通知需要显示加载状态
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("AIAnalysisNeedsLoading"), object: nil)
        }
        
        // 构建请求
        let request = createAnalysisRequest(content: content, isWordSelected: isWordSelected, targetLanguage: targetLanguage)
        
        // 发送请求
        performRequest(request, content: content, isWordSelected: isWordSelected, completion: completion)
    }
    
    // MARK: - 创建分析请求
    private func createAnalysisRequest(sentence: String) -> URLRequest {
        return createAnalysisRequest(content: sentence, isWordSelected: false, targetLanguage: "zh")
    }
    
    // MARK: - 创建智能分析请求
    private func createAnalysisRequest(content: String, isWordSelected: Bool, targetLanguage: String) -> URLRequest {
        // 获取当前厂商配置
        guard let providerConfig = apiKeyManager.getAPIConfig(for: currentProvider) else {
            print("❌ AI分析服务：无法获取厂商配置 - \(currentProvider)")
            // 使用默认智谱AI配置
            return createZhipuRequest(content: content, isWordSelected: isWordSelected, targetLanguage: targetLanguage)
        }
        
        // 根据厂商类型创建不同的请求
        switch currentProvider {
        case "zhipu_ai":
            return createZhipuRequest(content: content, isWordSelected: isWordSelected, targetLanguage: targetLanguage, config: providerConfig)
        case "gemini":
            return createGeminiRequest(content: content, isWordSelected: isWordSelected, targetLanguage: targetLanguage, config: providerConfig)
        default:
            print("❌ AI分析服务：不支持的厂商 - \(currentProvider)")
            return createZhipuRequest(content: content, isWordSelected: isWordSelected, targetLanguage: targetLanguage)
        }
    }
    
    // MARK: - 创建智谱AI请求
    private func createZhipuRequest(content: String, isWordSelected: Bool, targetLanguage: String, config: AIAPIKeyManager.AIProviderConfig? = nil) -> URLRequest {
        let apiConfig = config != nil ? (url: config!.apiUrl, model: config!.model, temperature: 0.7, maxTokens: 2000) : configManager.getAPIConfig()
        let apiKey = config?.apiKey ?? "cf81571047c041cb8cb69d9c7bfcf4b7.3sgdtoTaMYmlRtqj"
        
        print("🔑 使用智谱AI API密钥: \(apiKey.prefix(10))...")
        
        var request = URLRequest(url: URL(string: apiConfig.url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 生成智能提示词
        let prompt = configManager.generateSmartPrompt(
            content: content,
            isWordSelected: isWordSelected,
            targetLanguage: targetLanguage
        )
        
        print("📝 智谱AI提示词: \(prompt)")
        
        let requestBody = ZhipuRequest(
            model: apiConfig.model,
            messages: [
                ZhipuMessage(role: "user", content: prompt)
            ],
            temperature: apiConfig.temperature,
            max_tokens: apiConfig.maxTokens
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
            print("✅ 智谱AI请求体编码成功")
        } catch {
            print("❌ AI分析服务：编码智谱AI请求失败 - \(error)")
        }
        
        return request
    }
    
    // MARK: - 创建Gemini AI请求
    private func createGeminiRequest(content: String, isWordSelected: Bool, targetLanguage: String, config: AIAPIKeyManager.AIProviderConfig) -> URLRequest {
        // 构建Gemini API URL
        let urlString = "\(config.apiUrl)?key=\(config.apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ AI分析服务：无效的Gemini API URL")
            return URLRequest(url: URL(string: "about:blank")!)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 生成智能提示词
        let prompt = configManager.generateSmartPrompt(
            content: content,
            isWordSelected: isWordSelected,
            targetLanguage: targetLanguage
        )
        
        let requestBody = GeminiRequest(
            prompt: prompt,
            temperature: 0.7,
            maxTokens: 4000
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("❌ AI分析服务：编码Gemini请求失败 - \(error)")
        }
        
        return request
    }
    
    // MARK: - 创建分析提示词
    private func createAnalysisPrompt(sentence: String) -> String {
        // 从配置管理器获取提示词模板
        return configManager.generatePrompt(for: sentence)
    }
    
    // MARK: - 执行请求
    private func performRequest(_ request: URLRequest, sentence: String, completion: @escaping (Result<String, Error>) -> Void) {
        performRequest(request, content: sentence, isWordSelected: false, completion: completion)
    }
    
    // MARK: - 执行智能请求
    private func performRequest(_ request: URLRequest, content: String, isWordSelected: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        // 添加请求调试信息
        print("🔍 AI分析服务：开始请求")
        print("📡 当前厂商: \(currentProvider)")
        print("🌐 请求URL: \(request.url?.absoluteString ?? "未知")")
        print("📝 请求方法: \(request.httpMethod ?? "未知")")
        print("📋 请求头: \(request.allHTTPHeaderFields ?? [:])")
        
        if let body = request.httpBody {
            print("📦 请求体大小: \(body.count) bytes")
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 请求体内容: \(bodyString)")
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ AI分析服务：网络请求失败 - \(error)")
                    completion(.failure(error))
                    return
                }
                
                // 添加响应调试信息
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP状态码: \(httpResponse.statusCode)")
                    print("📋 响应头: \(httpResponse.allHeaderFields)")
                }
                
                guard let data = data else {
                    print("❌ AI分析服务：响应数据为空")
                    completion(.failure(AIAnalysisError.noData))
                    return
                }
                
                print("📦 响应数据大小: \(data.count) bytes")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 响应内容: \(responseString)")
                }
                
                // 根据当前厂商解析响应
                self.parseResponse(data: data, content: content, isWordSelected: isWordSelected, completion: completion)
            }
        }.resume()
    }
    
    // MARK: - 解析响应
    private func parseResponse(data: Data, content: String, isWordSelected: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            print("🔍 AI分析服务：开始解析响应 - 厂商: \(currentProvider)")
            
            switch currentProvider {
            case "zhipu_ai":
                print("📋 解析智谱AI响应...")
                let response = try JSONDecoder().decode(ZhipuResponse.self, from: data)
                print("✅ 智谱AI响应解析成功")
                
                if let resultContent = response.choices.first?.message.content {
                    print("✅ 智谱AI响应内容获取成功")
                    let _ = isWordSelected ? "单词" : "句子"
                    
                    // 缓存结果（使用内容+类型+提示词版本作为缓存键，与检查时保持一致）
                    let promptVersion = self.configManager.getPromptVersion()
                    let cacheKey = "\(isWordSelected ? "word" : "sentence"):\(promptVersion):\(content)"
                    self.cacheAnalysisResult(sentence: cacheKey, result: resultContent)
                    
                    completion(.success(resultContent))
                } else {
                    print("❌ AI分析服务：智谱AI响应内容为空")
                    print("📋 响应结构: \(response)")
                    completion(.failure(AIAnalysisError.noContent))
                }
                
            case "gemini":
                print("📋 解析Gemini响应...")
                let response = try JSONDecoder().decode(GeminiResponse.self, from: data)
                print("✅ Gemini响应解析成功")
                
                // 检查是否有错误
                if let error = response.error {
                    print("❌ AI分析服务：Gemini API错误 - \(error.message)")
                    completion(.failure(AIAnalysisError.apiError(error.message)))
                    return
                }
                
                if let candidates = response.candidates, 
                   let firstCandidate = candidates.first {
                    
                    // 检查finishReason
                    if let finishReason = firstCandidate.finishReason {
                        print("📋 Gemini完成原因: \(finishReason)")
                        
                        if finishReason == "MAX_TOKENS" {
                            print("⚠️ Gemini响应因达到最大token限制而截断")
                            // 即使截断，我们仍然尝试获取内容
                        }
                    }
                    
                    // 尝试获取内容
                    if let content = firstCandidate.content,
                       let firstPart = content.parts.first {
                        let resultContent = firstPart.text
                        print("✅ Gemini响应内容获取成功")
                        let _ = isWordSelected ? "单词" : "句子"
                        
                        // 缓存结果（使用内容+类型+提示词版本作为缓存键，与检查时保持一致）
                        let promptVersion = self.configManager.getPromptVersion()
                        let cacheKey = "\(isWordSelected ? "word" : "sentence"):\(promptVersion):\(content)"
                        self.cacheAnalysisResult(sentence: cacheKey, result: resultContent)
                        
                        completion(.success(resultContent))
                    } else {
                        print("❌ AI分析服务：Gemini响应内容为空")
                        print("📋 候选响应结构: \(firstCandidate)")
                        print("📋 完整响应结构: \(response)")
                        completion(.failure(AIAnalysisError.noContent))
                    }
                } else {
                    print("❌ AI分析服务：Gemini响应候选为空")
                    print("📋 响应结构: \(response)")
                    completion(.failure(AIAnalysisError.noContent))
                }
                
            default:
                print("❌ AI分析服务：不支持的厂商 - \(currentProvider)")
                completion(.failure(AIAnalysisError.providerNotSupported(currentProvider)))
            }
        } catch {
            print("❌ AI分析服务：解析响应失败 - \(error)")
            print("📋 错误详情: \(error.localizedDescription)")
            
            // 尝试解析原始响应以获取更多信息
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 原始响应内容: \(responseString)")
            }
            
            // 提供更具体的错误信息
            if error is DecodingError {
                completion(.failure(AIAnalysisError.apiError("响应格式错误，可能是API返回了意外的数据格式")))
            } else {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 缓存管理
    private func cacheAnalysisResult(sentence: String, result: String) {
        // 存储到缓存
        analysisCache[sentence] = result
        
        // 限制缓存大小
        if analysisCache.count > maxCacheSize {
            // 删除最旧的缓存条目（简单的FIFO策略）
            let keysToRemove = Array(analysisCache.keys.prefix(analysisCache.count - maxCacheSize))
            for key in keysToRemove {
                analysisCache.removeValue(forKey: key)
            }
            print("🧹 AI分析服务：清理缓存，当前缓存条目数：\(analysisCache.count)")
        }
        
    }
    
    // MARK: - 清理缓存
    func clearCache() {
        analysisCache.removeAll()
        print("🧹 AI分析服务：缓存已清理")
    }
    
    // MARK: - 强制清理缓存（用于调试）
    func forceClearCache() {
        analysisCache.removeAll()
        print("🧹 AI分析服务：强制清理缓存完成")
        print("📊 当前缓存条目数: \(analysisCache.count)")
    }
    
    // MARK: - 获取缓存统计
    func getCacheStats() -> (count: Int, maxSize: Int) {
        return (analysisCache.count, maxCacheSize)
    }
    
    // MARK: - 配置管理
    func reloadConfig() {
        configManager.reloadConfig()
        // 重新加载配置后清理缓存，确保使用新的提示词
        clearCache()
        print("🔄 AI分析服务：配置已重新加载，缓存已清理")
    }
    
    func getConfigInfo() -> String {
        return configManager.getConfigInfo()
    }
    
    func getPromptTemplate() -> String {
        return configManager.getPromptTemplate()
    }
    
    // MARK: - 智能分析接口
    func analyzeWithSmartPrompt(content: String, isWordSelected: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        analyzeContent(content, isWordSelected: isWordSelected, completion: completion)
    }
    
    // MARK: - 获取提示词模板
    func getWordPromptTemplate(for language: String = "zh") -> String {
        return configManager.getWordPromptTemplate(for: language)
    }
    
    func getSentencePromptTemplate(for language: String = "zh") -> String {
        return configManager.getSentencePromptTemplate(for: language)
    }
    
    // MARK: - 语言检测
    func detectLanguage(_ text: String) -> String {
        return configManager.detectLanguage(text)
    }
    
    // MARK: - AI厂商管理
    func setCurrentProvider(_ provider: String) {
        if apiKeyManager.validateAPIKey(for: provider) {
            currentProvider = provider
            print("✅ AI分析服务：已切换到 \(provider)")
        } else {
            print("❌ AI分析服务：无法切换到 \(provider)，API密钥无效或未启用")
        }
    }
    
    func getCurrentProvider() -> String {
        return currentProvider
    }
    
    func getAvailableProviders() -> [AIAPIKeyManager.AIProviderConfig] {
        return apiKeyManager.getEnabledProviders()
    }
    
    func getProviderNames() -> [String] {
        return apiKeyManager.getProviderNames()
    }
    
    func switchToProvider(by name: String) -> Bool {
        if apiKeyManager.getProviderConfig(by: name) != nil {
            // 根据配置名称找到对应的key
            for (_, providerConfig) in apiKeyManager.getEnabledProviders().enumerated() {
                if providerConfig.name == name {
                    // 这里需要从AIAPIKeyManager获取正确的key
                    // 暂时使用简单的映射
                    let providerKey = getProviderKey(by: name)
                    if let key = providerKey {
                        setCurrentProvider(key)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func getProviderKey(by name: String) -> String? {
        // 简单的名称到key的映射
        switch name {
        case "智谱AI (Zhipu AI)":
            return "zhipu_ai"
        case "Google Gemini 2.5 Flash":
            return "gemini"
        case "OpenAI GPT":
            return "openai"
        case "Claude (Anthropic)":
            return "claude"
        case "百度文心一言":
            return "baidu"
        case "阿里通义千问":
            return "alibaba"
        case "腾讯混元":
            return "tencent"
        case "字节豆包":
            return "doubao"
        default:
            return nil
        }
    }
}

// MARK: - 智谱AI请求模型
struct ZhipuRequest: Codable {
    let model: String
    let messages: [ZhipuMessage]
    let temperature: Double
    let max_tokens: Int
}

struct ZhipuMessage: Codable {
    let role: String
    let content: String
}

// MARK: - 智谱AI响应模型
struct ZhipuResponse: Codable {
    let choices: [ZhipuChoice]
}

struct ZhipuChoice: Codable {
    let message: ZhipuResponseMessage
}

struct ZhipuResponseMessage: Codable {
    let content: String
}

// MARK: - Gemini AI请求模型
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    
    init(prompt: String, temperature: Double = 0.7, maxTokens: Int = 4000) {
        self.contents = [
            GeminiContent(parts: [GeminiPart(text: prompt)])
        ]
        self.generationConfig = GeminiGenerationConfig(
            temperature: temperature,
            maxOutputTokens: maxTokens
        )
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
}

// MARK: - Gemini AI响应模型
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
    let finishReason: String?
    let index: Int?
}

struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - AI分析错误类型
enum AIAnalysisError: Error, LocalizedError {
    case noData
    case noContent
    case networkError(String)
    case providerNotSupported(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "AI分析服务：响应数据为空"
        case .noContent:
            return "AI分析服务：响应内容为空"
        case .networkError(let message):
            return "AI分析服务：网络错误 - \(message)"
        case .providerNotSupported(let provider):
            return "AI分析服务：不支持的AI厂商 - \(provider)"
        case .apiError(let message):
            return "AI分析服务：API错误 - \(message)"
        }
    }
}
