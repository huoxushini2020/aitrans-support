import Foundation

class TranslationService {
    static let shared: TranslationService = TranslationService()
    
    private init() {
        loadCacheFromDisk()
    }
    
    // 非官方Google翻译接口（免费但不稳定）
    private let baseURL = "https://translate.googleapis.com/translate_a/single"
    
    // MARK: - 防重复翻译机制
    private var currentTranslationTask: Task<String, Error>?
    private var lastTranslationRequest: (text: String, from: String, to: String)?
    private let translationQueue = DispatchQueue(label: "com.aitrans.translation", qos: .userInitiated)
    
    // MARK: - 持久化缓存机制
    private var translationCache: [String: CachedTranslation] = [:]
    private let maxCacheSize = 10000 // 最大缓存条目数
    private let maxTextLength = 100 // 单词最大长度（字符）
    private let cacheFileName = "translation_cache.json"
    private let cacheDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("AITrans")
    
    // 缓存数据结构
    private struct CachedTranslation: Codable {
        let result: String
        let timestamp: Date
        var accessCount: Int
        var lastAccessed: Date
        
        init(result: String) {
            self.result = result
            self.timestamp = Date()
            self.accessCount = 1
            self.lastAccessed = Date()
        }
    }
    
    func translate(text: String, from sourceLanguage: String = "auto", to targetLanguage: String = "zh") async throws -> String {
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }
        
        // 检查是否是重复的翻译请求
        let currentRequest = (text: text, from: sourceLanguage, to: targetLanguage)
        if let lastRequest = lastTranslationRequest,
           lastRequest.text == currentRequest.text &&
           lastRequest.from == currentRequest.from &&
           lastRequest.to == currentRequest.to {
            
            // 如果有正在进行的翻译任务，等待它完成
            if let currentTask = currentTranslationTask {
                do {
                    let result = try await currentTask.value
                    return result
                } catch {
                }
            }
        }
        
        // 检查缓存（只缓存单词）
        if isWord(text: text) {
            let cacheKey = "\(sourceLanguage)|\(targetLanguage)|\(text)"
            if let cachedTranslation = translationCache[cacheKey] {
                print("🎯 翻译服务：使用缓存结果 - \(text)")
                // 更新访问统计
                updateCacheAccess(cacheKey: cacheKey)
                return cachedTranslation.result
            }
        }
        
        // 取消之前的翻译任务
        currentTranslationTask?.cancel()
        
        // 创建新的翻译任务
        let translationTask = Task {
            let result = try await translateWithGoogle(text: text, from: sourceLanguage, to: targetLanguage)
            return result
        }
        
        currentTranslationTask = translationTask
        lastTranslationRequest = currentRequest
        
        do {
            let result = try await translationTask.value
            currentTranslationTask = nil
            
            // 缓存结果（只缓存单词）
            if isWord(text: text) {
                cacheTranslationResult(text: text, from: sourceLanguage, to: targetLanguage, result: result)
            }
            
            return result
        } catch {
            currentTranslationTask = nil
            throw error
        }
    }
    
    private func translateWithGoogle(text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // 使用非官方Google翻译接口
        let urlString = "\(baseURL)?client=gtx&sl=\(sourceLanguage)&tl=\(targetLanguage)&dt=t&q=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // 模拟真实浏览器请求
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("https://translate.google.com/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 30.0
        
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkError
            }
            
            
            guard httpResponse.statusCode == 200 else {
                if String(data: data, encoding: .utf8) != nil {
                }
                throw TranslationError.networkError
            }
            
            // 解析非官方Google翻译的JSON响应格式
            // 格式: [ [["翻译结果","原文",,,1]],,"源语言"]
            guard let json = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                throw TranslationError.invalidResponse
            }
            
            
            // 检查是否是预期的数组格式
            guard json.count >= 1,
                  let firstElement = json[0] as? [Any],
                  let translationArray = firstElement.first as? [Any],
                  translationArray.count >= 1,
                  let translatedText = translationArray[0] as? String,
                  !translatedText.isEmpty else {
                throw TranslationError.invalidResponse
            }
            
            return translatedText
            
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkError
        }
    }
}

enum TranslationError: Error {
    case invalidURL
    case networkError
    case invalidResponse
}

// MARK: - 缓存管理扩展
extension TranslationService {
    
    // MARK: - 单词检测
    private func isWord(text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查长度限制
        guard trimmedText.count <= maxTextLength else {
            return false
        }
        
        // 检查是否为空
        guard !trimmedText.isEmpty else {
            return false
        }
        
        // 检查是否包含空格（句子通常包含空格）
        if trimmedText.contains(" ") {
            return false
        }
        
        // 检查是否包含多个标点符号（句子通常包含多个标点）
        let punctuation = CharacterSet.punctuationCharacters
        let punctuationCount = trimmedText.components(separatedBy: punctuation).count - 1
        if punctuationCount > 1 {
            return false
        }
        
        // 检查是否包含字母（单词通常包含字母）
        let letters = CharacterSet.letters
        if trimmedText.rangeOfCharacter(from: letters) == nil {
            return false
        }
        
        // 允许的字符：字母、数字、连字符、下划线
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let disallowedCharacters = allowedCharacters.inverted
        if trimmedText.rangeOfCharacter(from: disallowedCharacters) != nil {
            return false
        }
        
        return true
    }
    
    // MARK: - 缓存存储
    private func cacheTranslationResult(text: String, from sourceLanguage: String, to targetLanguage: String, result: String) {
        let cacheKey = "\(sourceLanguage)|\(targetLanguage)|\(text)"
        
        // 存储到缓存
        translationCache[cacheKey] = CachedTranslation(result: result)
        
        // 检查缓存大小限制
        if translationCache.count > maxCacheSize {
            cleanupCache()
        }
        
        // 异步保存到磁盘
        saveCacheToDisk()
        
        print("💾 翻译服务：结果已缓存 - \(text) -> \(result)")
    }
    
    // MARK: - 缓存访问更新
    private func updateCacheAccess(cacheKey: String) {
        guard var cachedTranslation = translationCache[cacheKey] else { return }
        
        // 更新访问统计
        cachedTranslation.accessCount += 1
        cachedTranslation.lastAccessed = Date()
        
        translationCache[cacheKey] = cachedTranslation
        
        // 异步保存到磁盘
        saveCacheToDisk()
    }
    
    // MARK: - 缓存清理（LRU策略）
    private func cleanupCache() {
        let currentCount = translationCache.count
        let itemsToRemove = currentCount - maxCacheSize
        
        if itemsToRemove > 0 {
            // 按最后访问时间排序，删除最旧的条目
            let sortedItems = translationCache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
            let keysToRemove = Array(sortedItems.prefix(itemsToRemove)).map { $0.key }
            
            for key in keysToRemove {
                translationCache.removeValue(forKey: key)
            }
            
            print("🧹 翻译服务：清理缓存，删除了 \(itemsToRemove) 个条目，当前缓存条目数：\(translationCache.count)")
        }
    }
    
    // MARK: - 磁盘存储
    private func saveCacheToDisk() {
        guard let cacheDirectory = cacheDirectory else { return }
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        
        do {
            let data = try JSONEncoder().encode(translationCache)
            try data.write(to: cacheFileURL)
            print("💾 翻译服务：缓存已保存到磁盘")
        } catch {
            print("❌ 翻译服务：保存缓存失败 - \(error)")
        }
    }
    
    // MARK: - 磁盘加载
    private func loadCacheFromDisk() {
        guard let cacheDirectory = cacheDirectory else { return }
        
        let cacheFileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            print("📁 翻译服务：缓存文件不存在，使用空缓存")
            return
        }
        
        do {
            let data = try Data(contentsOf: cacheFileURL)
            translationCache = try JSONDecoder().decode([String: CachedTranslation].self, from: data)
            print("📁 翻译服务：缓存已从磁盘加载，条目数：\(translationCache.count)")
        } catch {
            print("❌ 翻译服务：加载缓存失败 - \(error)")
            translationCache = [:]
        }
    }
    
    // MARK: - 公共缓存管理方法
    func clearCache() {
        translationCache.removeAll()
        saveCacheToDisk()
        print("🧹 翻译服务：缓存已清理")
    }
    
    func getCacheStats() -> (count: Int, maxSize: Int, memoryUsage: String) {
        let count = translationCache.count
        let maxSize = maxCacheSize
        
        // 估算内存使用量
        let estimatedMemoryUsage = count * 200 // 每个条目约200字节
        let memoryUsageString = formatMemoryUsage(estimatedMemoryUsage)
        
        return (count, maxSize, memoryUsageString)
    }
    
    private func formatMemoryUsage(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}