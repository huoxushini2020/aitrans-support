//
//  AIPromptConfigManager.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation

// MARK: - AI提示词配置管理器
class AIPromptConfigManager {
    
    // MARK: - 单例
    static let shared = AIPromptConfigManager()
    
    // MARK: - 配置模型
    struct AIPromptConfig: Codable {
        let aiAnalysis: AIAnalysisConfig
        let version: String
        let lastUpdated: String
        let description: String
        
        enum CodingKeys: String, CodingKey {
            case aiAnalysis = "ai_analysis"
            case version
            case lastUpdated = "last_updated"
            case description
        }
    }
    
    struct AIAnalysisConfig: Codable {
        let serviceProvider: String
        let model: String
        let apiUrl: String
        let temperature: Double
        let maxTokens: Int
        let promptTemplates: PromptTemplates
        let analysisSections: [AnalysisSection]
        let outputRequirements: OutputRequirements
        let languageDetection: LanguageDetection
        let promptSelection: PromptSelection
        let defaultAIProvider: DefaultAIProvider
        
        enum CodingKeys: String, CodingKey {
            case serviceProvider = "service_provider"
            case model
            case apiUrl = "api_url"
            case temperature
            case maxTokens = "max_tokens"
            case promptTemplates = "prompt_templates"
            case analysisSections = "analysis_sections"
            case outputRequirements = "output_requirements"
            case languageDetection = "language_detection"
            case promptSelection = "prompt_selection"
            case defaultAIProvider = "default_ai_provider"
        }
    }
    
    struct DefaultAIProvider: Codable {
        let providerKey: String
        let providerName: String
        let autoSaveUserChoice: Bool
        
        enum CodingKeys: String, CodingKey {
            case providerKey = "provider_key"
            case providerName = "provider_name"
            case autoSaveUserChoice = "auto_save_user_choice"
        }
    }
    
    struct PromptTemplates: Codable {
        let word: LanguageTemplates
        let sentence: LanguageTemplates
    }
    
    struct LanguageTemplates: Codable {
        let zh: String
        let en: String
        let th: String?
        let ja: String?
        let ko: String?
        let vi: String?
        let de: String?
        let fr: String?
        let es: String?
        let zhTW: String?
        
        enum CodingKeys: String, CodingKey {
            case zh, en, th, ja, ko, vi, de, fr, es
            case zhTW = "zh-TW"
        }
    }
    
    struct LanguageDetection: Codable {
        let defaultLanguage: String
        let supportedLanguages: [String]
        let autoDetect: Bool
        
        enum CodingKeys: String, CodingKey {
            case defaultLanguage = "default_language"
            case supportedLanguages = "supported_languages"
            case autoDetect = "auto_detect"
        }
    }
    
    struct PromptSelection: Codable {
        let wordAnalysisTrigger: String
        let sentenceAnalysisTrigger: String
        let fallbackToSentence: Bool
        
        enum CodingKeys: String, CodingKey {
            case wordAnalysisTrigger = "word_analysis_trigger"
            case sentenceAnalysisTrigger = "sentence_analysis_trigger"
            case fallbackToSentence = "fallback_to_sentence"
        }
    }
    
    struct AnalysisSection: Codable {
        let title: String
        let description: String
    }
    
    struct OutputRequirements: Codable {
        let language: String
        let format: String
        let style: String
        let structure: String
    }
    
    // MARK: - 属性
    private var config: AIPromptConfig?
    private let configFileName = "ai_prompt_config.json"
    
    // MARK: - 私有初始化
    private init() {
        loadConfig()
    }
    
    // MARK: - 加载配置
    private func loadConfig() {
        // 优先从用户可写目录加载配置
        if let writableConfigURL = getWritableConfigURL(),
           FileManager.default.fileExists(atPath: writableConfigURL.path) {
            loadConfigFromURL(writableConfigURL, source: "用户配置")
        } else if let bundleConfigURL = getConfigURL() {
            loadConfigFromURL(bundleConfigURL, source: "默认配置")
        } else {
            print("❌ AIPromptConfigManager: 无法找到配置文件")
            createDefaultConfig()
        }
    }
    
    private func loadConfigFromURL(_ configURL: URL, source: String) {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            config = try decoder.decode(AIPromptConfig.self, from: data)
            print("✅ AIPromptConfigManager: 成功加载AI提示词配置 (\(source))")
            print("📋 配置版本: \(config?.version ?? "未知")")
            print("📅 最后更新: \(config?.lastUpdated ?? "未知")")
            print("📁 配置文件: \(configURL.path)")
        } catch {
            print("❌ AIPromptConfigManager: 加载配置文件失败 (\(source)) - \(error)")
            if source == "用户配置" {
                // 如果用户配置加载失败，尝试从Bundle加载
                if let bundleConfigURL = getConfigURL() {
                    loadConfigFromURL(bundleConfigURL, source: "默认配置")
                } else {
                    createDefaultConfig()
                }
            } else {
                createDefaultConfig()
            }
        }
    }
    
    // MARK: - 获取配置文件URL
    private func getConfigURL() -> URL? {
        // 首先尝试从Bundle中获取
        if let bundleURL = Bundle.main.url(forResource: "ai_prompt_config", withExtension: "json") {
            return bundleURL
        }
        
        // 如果Bundle中没有，尝试从项目目录获取
        let projectURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("AITrans/Config/ai_prompt_config.json")
        
        if FileManager.default.fileExists(atPath: projectURL.path) {
            return projectURL
        }
        
        return nil
    }
    
    // MARK: - 创建默认配置
    private func createDefaultConfig() {
        print("⚠️ AIPromptConfigManager: 创建默认配置并保存到文件")
        
        // 从Bundle中读取正确的配置
        if let bundleConfigURL = getConfigURL() {
            do {
                let data = try Data(contentsOf: bundleConfigURL)
                let decoder = JSONDecoder()
                config = try decoder.decode(AIPromptConfig.self, from: data)
                print("✅ AIPromptConfigManager: 从Bundle成功加载配置")
                
                // 保存到用户可写目录
                saveConfigToFile()
                return
            } catch {
                print("❌ AIPromptConfigManager: 从Bundle加载配置失败 - \(error)")
            }
        }
        
        // 如果Bundle加载失败，创建硬编码配置（但这种情况不应该发生）
        print("❌ AIPromptConfigManager: 无法从Bundle加载配置，使用硬编码配置")
        config = AIPromptConfig(
            aiAnalysis: AIAnalysisConfig(
                serviceProvider: "智谱AI (Zhipu AI)",
                model: "glm-4-flash",
                apiUrl: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
                temperature: 0.7,
                maxTokens: 2000,
                promptTemplates: PromptTemplates(
                    word: LanguageTemplates(
                        zh: getDefaultWordPromptTemplate(for: "zh"),
                        en: getDefaultWordPromptTemplate(for: "en"),
                        th: getDefaultWordPromptTemplate(for: "th"),
                        ja: getDefaultWordPromptTemplate(for: "ja"),
                        ko: getDefaultWordPromptTemplate(for: "ko"),
                        vi: getDefaultWordPromptTemplate(for: "vi"),
                        de: getDefaultWordPromptTemplate(for: "de"),
                        fr: getDefaultWordPromptTemplate(for: "fr"),
                        es: getDefaultWordPromptTemplate(for: "es"),
                        zhTW: getDefaultWordPromptTemplate(for: "zh-TW")
                    ),
                    sentence: LanguageTemplates(
                        zh: getDefaultSentencePromptTemplate(for: "zh"),
                        en: getDefaultSentencePromptTemplate(for: "en"),
                        th: getDefaultSentencePromptTemplate(for: "th"),
                        ja: getDefaultSentencePromptTemplate(for: "ja"),
                        ko: getDefaultSentencePromptTemplate(for: "ko"),
                        vi: getDefaultSentencePromptTemplate(for: "vi"),
                        de: getDefaultSentencePromptTemplate(for: "de"),
                        fr: getDefaultSentencePromptTemplate(for: "fr"),
                        es: getDefaultSentencePromptTemplate(for: "es"),
                        zhTW: getDefaultSentencePromptTemplate(for: "zh-TW")
                    )
                ),
                analysisSections: [
                    AnalysisSection(title: "翻译", description: "目标语言翻译"),
                    AnalysisSection(title: "词汇短语解析", description: "关键单词 + 目标语言释义"),
                    AnalysisSection(title: "语法结构", description: "说明主语、谓语、从句等"),
                    AnalysisSection(title: "例句练习", description: "用相同结构或替换单词造新句")
                ],
                outputRequirements: OutputRequirements(
                    language: "中文",
                    format: "Markdown",
                    style: "清晰易读",
                    structure: "结构化输出"
                ),
                languageDetection: LanguageDetection(
                    defaultLanguage: "zh",
                    supportedLanguages: ["zh", "en"],
                    autoDetect: true
                ),
                promptSelection: PromptSelection(
                    wordAnalysisTrigger: "selected_word",
                    sentenceAnalysisTrigger: "no_selection",
                    fallbackToSentence: true
                ),
                defaultAIProvider: DefaultAIProvider(
                    providerKey: "zhipu_ai",
                    providerName: "智谱AI (Zhipu AI)",
                    autoSaveUserChoice: true
                )
            ),
            version: "1.0.0",
            lastUpdated: "2024-12-09",
            description: "AI详细翻译提示词配置文件"
        )
        
        // 保存到文件
        saveConfigToFile()
    }
    
    // MARK: - 重新加载配置
    func reloadConfig() {
        print("🔄 AIPromptConfigManager: 重新加载配置")
        loadConfig()
    }
    
    // MARK: - 强制重新加载配置（清除缓存）
    func forceReloadConfig() {
        print("🔄 AIPromptConfigManager: 强制重新加载配置")
        
        // 删除用户配置文件，强制从Bundle重新加载
        if let writableConfigURL = getWritableConfigURL(),
           FileManager.default.fileExists(atPath: writableConfigURL.path) {
            do {
                try FileManager.default.removeItem(at: writableConfigURL)
                print("🗑️ AIPromptConfigManager: 已删除用户配置文件")
            } catch {
                print("❌ AIPromptConfigManager: 删除用户配置文件失败 - \(error)")
            }
        }
        
        // 重新加载配置
        loadConfig()
    }
    
    // MARK: - 获取提示词版本
    func getPromptVersion() -> String {
        guard let config = config else {
            return "default"
        }
        return "\(config.version)_\(config.lastUpdated)"
    }
    
    // MARK: - 获取提示词模板
    func getPromptTemplate() -> String {
        return getSentencePromptTemplate(for: "zh")
    }
    
    // MARK: - 获取单词提示词模板
    func getWordPromptTemplate(for language: String = "zh") -> String {
        guard let config = config else {
            return getDefaultWordPromptTemplate(for: language)
        }
        
        let templates = config.aiAnalysis.promptTemplates.word
        switch language {
        case "en":
            return templates.en
        case "zh":
            return templates.zh
        case "th":
            return templates.th ?? templates.zh
        case "ja":
            return templates.ja ?? templates.zh
        case "ko":
            return templates.ko ?? templates.zh
        case "vi":
            return templates.vi ?? templates.zh
        case "de":
            return templates.de ?? templates.zh
        case "fr":
            return templates.fr ?? templates.zh
        case "es":
            return templates.es ?? templates.zh
        case "zh-TW", "zh-TW":
            return templates.zhTW ?? templates.zh
        default:
            return templates.zh // 默认返回中文
        }
    }
    
    // MARK: - 获取句子提示词模板
    func getSentencePromptTemplate(for language: String = "zh") -> String {
        guard let config = config else {
            return getDefaultSentencePromptTemplate(for: language)
        }
        
        let templates = config.aiAnalysis.promptTemplates.sentence
        switch language {
        case "en":
            return templates.en
        case "zh":
            return templates.zh
        case "th":
            return templates.th ?? templates.zh
        case "ja":
            return templates.ja ?? templates.zh
        case "ko":
            return templates.ko ?? templates.zh
        case "vi":
            return templates.vi ?? templates.zh
        case "de":
            return templates.de ?? templates.zh
        case "fr":
            return templates.fr ?? templates.zh
        case "es":
            return templates.es ?? templates.zh
        case "zh-TW", "zh-TW":
            return templates.zhTW ?? templates.zh
        default:
            return templates.zh // 默认返回中文
        }
    }
    
    // MARK: - 获取API配置
    func getAPIConfig() -> (url: String, model: String, temperature: Double, maxTokens: Int) {
        guard let aiConfig = config?.aiAnalysis else {
            return getDefaultAPIConfig()
        }
        
        return (
            url: aiConfig.apiUrl,
            model: aiConfig.model,
            temperature: aiConfig.temperature,
            maxTokens: aiConfig.maxTokens
        )
    }
    
    // MARK: - 生成提示词
    func generatePrompt(for sentence: String) -> String {
        return generateSentencePrompt(for: sentence, language: "zh")
    }
    
    // MARK: - 生成单词提示词
    func generateWordPrompt(for word: String, language: String = "zh") -> String {
        let template = getWordPromptTemplate(for: language)
        return template.replacingOccurrences(of: "{word}", with: word)
    }
    
    // MARK: - 生成句子提示词
    func generateSentencePrompt(for sentence: String, language: String = "zh") -> String {
        let template = getSentencePromptTemplate(for: language)
        return template.replacingOccurrences(of: "{sentence}", with: sentence)
    }
    
    // MARK: - 生成带目标语言的句子提示词
    func generateSentencePrompt(for sentence: String, targetLanguage: String, language: String = "zh") -> String {
        let template = getSentencePromptTemplate(for: language)
        var prompt = template.replacingOccurrences(of: "{sentence}", with: sentence)
        prompt = prompt.replacingOccurrences(of: "{target_language}", with: targetLanguage)
        return prompt
    }
    
    // MARK: - 生成带目标语言的单词提示词
    func generateWordPrompt(for word: String, targetLanguage: String, language: String = "zh") -> String {
        let template = getWordPromptTemplate(for: language)
        var prompt = template.replacingOccurrences(of: "{word}", with: word)
        prompt = prompt.replacingOccurrences(of: "{target_language}", with: targetLanguage)
        return prompt
    }
    
    // MARK: - 智能生成提示词（根据选中状态）
    func generateSmartPrompt(content: String, isWordSelected: Bool, targetLanguage: String = "zh") -> String {
        // 获取目标语言的中文名称
        let targetLanguageName = getTargetLanguageName(targetLanguage)
        
        // 根据目标语言选择合适的提示词模板语言
        let promptLanguage = getPromptLanguage(for: targetLanguage)
        
        if isWordSelected {
            print("📝 AIPromptConfigManager: 生成单词分析提示词，目标语言: \(targetLanguageName)，提示词语言: \(promptLanguage)")
            return generateWordPrompt(for: content, targetLanguage: targetLanguageName, language: promptLanguage)
        } else {
            print("📝 AIPromptConfigManager: 生成句子分析提示词，目标语言: \(targetLanguageName)，提示词语言: \(promptLanguage)")
            return generateSentencePrompt(for: content, targetLanguage: targetLanguageName, language: promptLanguage)
        }
    }
    
    // MARK: - 根据目标语言获取提示词模板语言
    private func getPromptLanguage(for targetLanguage: String) -> String {
        // 根据目标语言选择合适的提示词模板语言
        switch targetLanguage {
        case "en", "en-US":
            return "en"
        case "th", "th-TH":
            return "th"
        case "ja", "ja-JP":
            return "ja"
        case "ko", "ko-KR":
            return "ko"
        case "vi", "vi-VN":
            return "vi"
        case "de", "de-DE":
            return "de"
        case "fr", "fr-FR":
            return "fr"
        case "es", "es-ES":
            return "es"
        case "zh-TW", "zh-Hant":
            return "zh-TW"
        default:
            return "zh" // 其他语言使用中文提示词模板
        }
    }
    
    // MARK: - 获取目标语言的中文名称
    private func getTargetLanguageName(_ languageCode: String) -> String {
        let languageMap: [String: String] = [
            "en": "英语",
            "en-US": "英语",
            "zh": "中文",
            "zh-CN": "中文",
            "zh-Hans": "中文",
            "zh-TW": "繁体中文",
            "zh-Hant": "繁体中文",
            "es": "西班牙语",
            "es-ES": "西班牙语",
            "fr": "法语",
            "fr-FR": "法语",
            "de": "德语",
            "de-DE": "德语",
            "ja": "日语",
            "ja-JP": "日语",
            "ko": "韩语",
            "ko-KR": "韩语",
            "th": "泰语",
            "th-TH": "泰语",
            "vi": "越南语",
            "vi-VN": "越南语"
        ]
        
        // 首先尝试直接匹配
        if let languageName = languageMap[languageCode] {
            return languageName
        }
        
        // 如果直接匹配失败，尝试提取主要语言代码（如从 "th-TH" 提取 "th"）
        let mainLanguageCode = languageCode.components(separatedBy: "-").first ?? languageCode
        if let languageName = languageMap[mainLanguageCode] {
            return languageName
        }
        
        // 如果都找不到，返回原始语言代码而不是默认的"中文"
        print("⚠️ AIPromptConfigManager: 未找到语言代码 '\(languageCode)' 的映射，使用原始代码")
        return languageCode
    }
    
    // MARK: - 检测语言
    func detectLanguage(_ text: String) -> String {
        guard let config = config, config.aiAnalysis.languageDetection.autoDetect else {
            return config?.aiAnalysis.languageDetection.defaultLanguage ?? "zh"
        }
        
        // 改进的语言检测逻辑
        let chinesePattern = "[\\u4e00-\\u9fff]"
        let englishPattern = "[a-zA-Z]"
        
        // 计算中文字符数量
        let chineseMatches = text.range(of: chinesePattern, options: .regularExpression)
        let chineseCount = chineseMatches != nil ? 1 : 0
        
        // 计算英文字符数量
        let englishMatches = text.range(of: englishPattern, options: .regularExpression)
        let englishCount = englishMatches != nil ? 1 : 0
        
        // 如果包含中文字符，优先使用中文
        if chineseCount > 0 {
            return "zh"
        }
        // 如果只有英文字符，根据上下文判断
        else if englishCount > 0 {
            // 在翻译环境中，即使是英文单词，也应该用中文解释
            // 因为用户想要的是中文解释
            return "zh"
        }
        // 默认使用配置的语言
        else {
            return config.aiAnalysis.languageDetection.defaultLanguage
        }
    }
    
    // MARK: - 默认AI厂商管理
    func getDefaultAIProvider() -> (key: String, name: String) {
        guard let config = config else {
            return ("zhipu_ai", "智谱AI (Zhipu AI)")
        }
        
        return (config.aiAnalysis.defaultAIProvider.providerKey, config.aiAnalysis.defaultAIProvider.providerName)
    }
    
    func setDefaultAIProvider(key: String, name: String) {
        guard var config = config else { return }
        
        // 更新配置
        let newDefaultProvider = DefaultAIProvider(
            providerKey: key,
            providerName: name,
            autoSaveUserChoice: config.aiAnalysis.defaultAIProvider.autoSaveUserChoice
        )
        
        let newAIAnalysis = AIAnalysisConfig(
            serviceProvider: config.aiAnalysis.serviceProvider,
            model: config.aiAnalysis.model,
            apiUrl: config.aiAnalysis.apiUrl,
            temperature: config.aiAnalysis.temperature,
            maxTokens: config.aiAnalysis.maxTokens,
            promptTemplates: config.aiAnalysis.promptTemplates,
            analysisSections: config.aiAnalysis.analysisSections,
            outputRequirements: config.aiAnalysis.outputRequirements,
            languageDetection: config.aiAnalysis.languageDetection,
            promptSelection: config.aiAnalysis.promptSelection,
            defaultAIProvider: newDefaultProvider
        )
        
        let newConfig = AIPromptConfig(
            aiAnalysis: newAIAnalysis,
            version: config.version,
            lastUpdated: getCurrentDateString(),
            description: config.description
        )
        
        self.config = newConfig
        
        // 保存到配置文件
        saveConfigToFile()
        
        print("✅ AIPromptConfigManager: 已设置默认AI厂商为 \(name) (\(key))")
    }
    
    private func saveConfigToFile() {
        guard let config = config else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            
            // 获取用户可写的配置目录
            if let configURL = getWritableConfigURL() {
                try data.write(to: configURL)
                print("✅ AIPromptConfigManager: 配置已保存到文件: \(configURL.path)")
            } else {
                print("❌ AIPromptConfigManager: 无法获取可写配置文件路径")
            }
        } catch {
            print("❌ AIPromptConfigManager: 保存配置失败 - \(error)")
        }
    }
    
    // MARK: - 获取可写的配置文件URL
    private func getWritableConfigURL() -> URL? {
        // 获取应用支持目录
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ 无法获取Application Support目录")
            return nil
        }
        
        // 创建AITrans子目录
        let appDirectory = appSupportURL.appendingPathComponent("AITrans")
        
        // 确保目录存在
        do {
            try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ 无法创建应用目录: \(error)")
            return nil
        }
        
        // 返回配置文件URL
        return appDirectory.appendingPathComponent("ai_prompt_config.json")
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - 获取配置信息
    func getConfigInfo() -> String {
        guard let config = config else {
            return "配置未加载"
        }
        
        return """
        AI提示词配置信息:
        • 版本: \(config.version)
        • 最后更新: \(config.lastUpdated)
        • 服务提供商: \(config.aiAnalysis.serviceProvider)
        • 模型: \(config.aiAnalysis.model)
        • 温度: \(config.aiAnalysis.temperature)
        • 最大令牌: \(config.aiAnalysis.maxTokens)
        • 分析章节数: \(config.aiAnalysis.analysisSections.count)
        """
    }
    
    // MARK: - 默认配置
    private func getDefaultWordPromptTemplate(for language: String) -> String {
        switch language {
        case "en":
            return "Please provide a detailed lexical analysis of the following word in Markdown format: Word: {word} Please include the following analysis: 1. **Pronunciation & Phonetics**: IPA transcription 2. **Basic Definition & Part of Speech**: Primary part of speech, basic meanings, common definitions 3. **Meaning Analysis**: Detailed meanings, core usage 4. **Synonyms & Antonyms**: Related synonyms, antonyms, near-synonyms 5. **Fixed Collocations**: Common collocations, phrases, idiomatic usage 6. **Example Sentences**: Typical examples, usage samples Please respond in English with clear and readable formatting."
        case "th":
            return "กรุณาวิเคราะห์คำศัพท์ต่อไปนี้อย่างละเอียดในภาษาที่กำหนด โดยใช้รูปแบบ Markdown: **คำ:** {word} **ภาษาที่กำหนด:** {target_language} กรุณาให้การวิเคราะห์ต่อไปนี้: 1. **การออกเสียงและสัทศาสตร์**: สัญลักษณ์ IPA 2. **ความหมายพื้นฐานและชนิดของคำ**: ชนิดของคำหลัก ความหมายพื้นฐาน คำจำกัดความทั่วไป 3. **การวิเคราะห์ความหมาย**: ความหมายโดยละเอียด การใช้งานหลัก 4. **คำพ้องและคำตรงข้าม**: คำพ้องที่เกี่ยวข้อง คำตรงข้าม คำใกล้เคียง 5. **การจัดวางคำ**: การจัดวางที่ใช้บ่อย วลี การใช้งานที่เป็นนิสัย 6. **ประโยคตัวอย่าง**: ตัวอย่างทั่วไป ตัวอย่างการใช้งาน **สำคัญ: กรุณาตอบในภาษาที่กำหนดด้วยรูปแบบที่ชัดเจนและอ่านง่าย**"
        case "ja":
            return "指定された言語で以下の単語の詳細な語彙分析をMarkdown形式で提供してください：**単語:** {word}**対象言語:** {target_language}以下の分析内容を提供してください：1. **発音と音声学**：IPA表記2. **基本定義と品詞**：主要品詞、基本意味、一般的な定義3. **意味分析**：詳細な意味、核心的な用法4. **同義語と反義語**：関連する同義語、反義語、類義語5. **固定表現**：よく使われる組み合わせ、フレーズ、慣用表現6. **例文**：典型的な例、用法サンプル**重要：指定された言語で回答し、明確で読みやすい形式にしてください。**"
        case "ko":
            return "지정된 언어로 다음 단어의 상세한 어휘 분석을 Markdown 형식으로 제공해 주세요: **단어:** {word}**대상 언어:** {target_language}다음 분석 내용을 제공해 주세요: 1. **발음과 음성학**: IPA 표기 2. **기본 정의와 품사**: 주요 품사, 기본 의미, 일반적인 정의 3. **의미 분석**: 상세한 의미, 핵심적인 용법 4. **동의어와 반의어**: 관련된 동의어, 반의어, 유의어 5. **고정 표현**: 자주 사용되는 조합, 구문, 관용 표현 6. **예문**: 전형적인 예시, 용법 샘플 **중요: 지정된 언어로 답변하고 명확하고 읽기 쉬운 형식으로 해 주세요.**"
        case "vi":
            return "Vui lòng cung cấp phân tích từ vựng chi tiết của từ sau đây bằng ngôn ngữ đích theo định dạng Markdown: **Từ:** {word}**Ngôn ngữ đích:** {target_language} Vui lòng cung cấp các nội dung phân tích sau: 1. **Phát âm và ngữ âm học**: Ký hiệu IPA 2. **Định nghĩa cơ bản và từ loại**: Từ loại chính, nghĩa cơ bản, định nghĩa thông thường 3. **Phân tích nghĩa**: Nghĩa chi tiết, cách sử dụng cốt lõi 4. **Từ đồng nghĩa và trái nghĩa**: Từ đồng nghĩa liên quan, từ trái nghĩa, từ gần nghĩa 5. **Cụm từ cố định**: Các kết hợp thường dùng, cụm từ, cách dùng thành ngữ 6. **Ví dụ câu**: Các ví dụ điển hình, mẫu cách sử dụng **Quan trọng: Vui lòng trả lời bằng ngôn ngữ đích với định dạng rõ ràng và dễ đọc.**"
        case "de":
            return "Bitte geben Sie eine detaillierte lexikalische Analyse des folgenden Wortes in der Zielsprache im Markdown-Format an: **Wort:** {word}**Zielsprache:** {target_language} Bitte geben Sie folgende Analysen an: 1. **Aussprache und Phonetik**: IPA-Transkription 2. **Grunddefinition und Wortart**: Hauptwortart, Grundbedeutungen, allgemeine Definitionen 3. **Bedeutungsanalyse**: Detaillierte Bedeutungen, Kernverwendung 4. **Synonyme und Antonyme**: Verwandte Synonyme, Antonyme, ähnliche Wörter 5. **Feste Wendungen**: Häufig verwendete Kombinationen, Phrasen, idiomatische Verwendung 6. **Beispielsätze**: Typische Beispiele, Verwendungsbeispiele **Wichtig: Bitte antworten Sie in der Zielsprache mit klarer und lesbarer Formatierung.**"
        case "fr":
            return "Veuillez fournir une analyse lexicale détaillée du mot suivant dans la langue cible au format Markdown: **Mot:** {word}**Langue cible:** {target_language} Veuillez fournir les analyses suivantes: 1. **Prononciation et phonétique**: Transcription IPA 2. **Définition de base et classe de mot**: Classe de mot principale, significations de base, définitions courantes 3. **Analyse de la signification**: Significations détaillées, usage central 4. **Synonymes et antonymes**: Synonymes apparentés, antonymes, mots similaires 5. **Expressions figées**: Combinaisons fréquemment utilisées, phrases, usage idiomatique 6. **Exemples de phrases**: Exemples typiques, échantillons d'usage **Important: Veuillez répondre dans la langue cible avec un formatage clair et lisible.**"
        case "es":
            return "Por favor, proporcione un análisis léxico detallado de la siguiente palabra en el idioma objetivo usando formato Markdown: **Palabra:** {word}**Idioma objetivo:** {target_language} Por favor, proporcione los siguientes análisis: 1. **Pronunciación y fonética**: Transcripción IPA 2. **Definición básica y clase de palabra**: Clase de palabra principal, significados básicos, definiciones comunes 3. **Análisis de significado**: Significados detallados, uso central 4. **Sinónimos y antónimos**: Sinónimos relacionados, antónimos, palabras similares 5. **Expresiones fijas**: Combinaciones frecuentemente usadas, frases, uso idiomático 6. **Oraciones de ejemplo**: Ejemplos típicos, muestras de uso **Importante: Por favor, responda en el idioma objetivo con formato claro y legible.**"
        case "zh-TW":
            return "請用目標語言對以下單詞進行詳細的詞彙分析，請用Markdown格式返回分析結果：**單詞:** {word}**目標語言:** {target_language}請提供以下分析內容：1. **單詞發音符號**：國際音標(IPA)2. **基本釋義和詞性**：主要詞性、基本含義、常用釋義3. **詞義解析**：詳細含義、核心用法4. **同義詞和反義詞**：相關同義詞、反義詞、近義詞5. **固定搭配**：常用搭配、短語、習慣用法6. **例句**：典型例句、用法示例**重要：請務必用目標語言回答，格式要清晰易讀。**"
        default:
            return "请对以下单词进行详细的词汇分析，请用Markdown格式返回分析结果：单词：{word}请提供以下分析内容：1. **单词发音音标**：国际音标(IPA)2. **基本释义和词性**：主要词性、基本含义、常用释义3. **词义解析**：详细含义、核心用法4. **同义词和反义词**：相关同义词、反义词、近义词5. **固定搭配**：常用搭配、短语、习惯用法6. **例句**：典型例句、用法示例请用中文回答，格式要清晰易读。"
        }
    }
    
    private func getDefaultSentencePromptTemplate(for language: String) -> String {
        switch language {
        case "en":
            return "Please provide a detailed explanation and analysis of the following OCR-recognized sentence in the target language using Markdown format: **Original Sentence:** _\"{sentence}\"_ (OCR recognition result) Please include the following analysis: 1. **Target Language Translation**  - Accurately translate the OCR-recognized sentence to the target language 2. **Sentence Difficulty Analysis**  - Analyze grammatical difficulties, vocabulary challenges, and comprehension difficulties in the sentence 3. **Contextual Analysis**  - Analyze the meaning and usage of the sentence in specific contexts 4. **Usage Explanation**  - Explain grammatical structure, tense, voice, and other usage characteristics in detail 5. **Related Expressions**  - Provide similar expressions and practical example sentences Please respond in the target language with clear and readable formatting."
        case "th":
            return "กรุณาอธิบายและวิเคราะห์ประโยคที่ได้รับการจดจำจาก OCR ต่อไปนี้อย่างละเอียดในภาษาที่กำหนด โดยใช้รูปแบบ Markdown: **ประโยคต้นฉบับ:** _\"{sentence}\"_ (ผลการจดจำจาก OCR) **ภาษาที่กำหนด:** {target_language} กรุณาให้การวิเคราะห์ต่อไปนี้: 1. **การแปลเป็นภาษาที่กำหนด**  - แปลประโยคที่ได้รับการจดจำจาก OCR อย่างถูกต้องเป็นภาษาที่กำหนด 2. **การวิเคราะห์จุดยากของประโยค**  - วิเคราะห์จุดยากทางไวยากรณ์ ความยากของคำศัพท์ จุดยากในการทำความเข้าใจ 3. **การวิเคราะห์บริบท**  - วิเคราะห์ความหมายและการใช้งานของประโยคในบริบทเฉพาะ 4. **คำอธิบายการใช้งาน**  - อธิบายโครงสร้างไวยากรณ์ กาล วาจา และลักษณะการใช้งานอื่นๆ อย่างละเอียด 5. **การแสดงออกที่เกี่ยวข้อง**  - ให้การแสดงออกที่คล้ายกันและประโยคตัวอย่างที่เป็นประโยชน์ **สำคัญ: กรุณาตอบในภาษาที่กำหนดด้วยรูปแบบที่ชัดเจนและอ่านง่าย**"
        case "ja":
            return "指定された言語で以下のOCR認識された文の詳細な説明と分析をMarkdown形式で提供してください：**元の文:** _\"{sentence}\"_（OCR認識結果）**対象言語:** {target_language}以下の分析内容を提供してください：1. **対象言語への翻訳**  - OCR認識された文を対象言語に正確に翻訳する2. **文の難点解析**  - 文の文法の難点、語彙の難点、理解の難点を分析する3. **文脈分析**  - 特定の文脈における文の意味と用法を分析する4. **用法説明**  - 文の文法構造、時制、態などの用法特徴を詳しく説明する5. **関連表現**  - 類似表現と実用的な例文を提供する**重要：指定された言語で回答し、明確で読みやすい形式にしてください。**"
        case "ko":
            return "지정된 언어로 다음 OCR 인식된 문장의 상세한 설명과 분석을 Markdown 형식으로 제공해 주세요: **원문:** _\"{sentence}\"_（OCR 인식 결과）**대상 언어:** {target_language}다음 분석 내용을 제공해 주세요: 1. **대상 언어 번역**  - OCR 인식된 문장을 대상 언어로 정확히 번역하기 2. **문장 난점 분석**  - 문장의 문법 난점, 어휘 난점, 이해 난점 분석하기 3. **맥락 분석**  - 특정 맥락에서 문장의 의미와 용법 분석하기 4. **용법 설명**  - 문장의 문법 구조, 시제, 태 등의 용법 특징을 자세히 설명하기 5. **관련 표현**  - 유사한 표현과 실용적인 예문 제공하기 **중요: 지정된 언어로 답변하고 명확하고 읽기 쉬운 형식으로 해 주세요.**"
        case "vi":
            return "Vui lòng cung cấp giải thích và phân tích chi tiết câu được nhận dạng OCR sau đây bằng ngôn ngữ đích theo định dạng Markdown: **Câu gốc:** _\"{sentence}\"_（Kết quả nhận dạng OCR）**Ngôn ngữ đích:** {target_language} Vui lòng cung cấp các nội dung phân tích sau: 1. **Dịch sang ngôn ngữ đích**  - Dịch chính xác câu được nhận dạng OCR sang ngôn ngữ đích 2. **Phân tích điểm khó của câu**  - Phân tích các điểm khó về ngữ pháp, từ vựng, hiểu biết trong câu 3. **Phân tích ngữ cảnh**  - Phân tích ý nghĩa và cách sử dụng của câu trong ngữ cảnh cụ thể 4. **Giải thích cách sử dụng**  - Giải thích chi tiết cấu trúc ngữ pháp, thì, thể và các đặc điểm sử dụng khác của câu 5. **Biểu đạt liên quan**  - Cung cấp các biểu đạt tương tự và câu ví dụ thực tế **Quan trọng: Vui lòng trả lời bằng ngôn ngữ đích với định dạng rõ ràng và dễ đọc.**"
        case "de":
            return "Bitte geben Sie eine detaillierte Erklärung und Analyse des folgenden OCR-erkannten Satzes in der Zielsprache im Markdown-Format an: **Ursprünglicher Satz:** _\"{sentence}\"_（OCR-Erkennungsergebnis）**Zielsprache:** {target_language} Bitte geben Sie folgende Analysen an: 1. **Übersetzung in die Zielsprache**  - Übersetzen Sie den OCR-erkannten Satz genau in die Zielsprache 2. **Analyse der Satzschwierigkeiten**  - Analysieren Sie grammatische Schwierigkeiten, Vokabularschwierigkeiten und Verständnisschwierigkeiten im Satz 3. **Kontextanalyse**  - Analysieren Sie die Bedeutung und Verwendung des Satzes in spezifischen Kontexten 4. **Verwendungserklärung**  - Erklären Sie die grammatische Struktur, Zeitform, Stimme und andere Verwendungsmerkmale des Satzes im Detail 5. **Verwandte Ausdrücke**  - Bieten Sie ähnliche Ausdrücke und praktische Beispielsätze **Wichtig: Bitte antworten Sie in der Zielsprache mit klarer und lesbarer Formatierung.**"
        case "fr":
            return "Veuillez fournir une explication et une analyse détaillées de la phrase suivante reconnue par OCR dans la langue cible au format Markdown: **Phrase originale:** _\"{sentence}\"_（Résultat de reconnaissance OCR）**Langue cible:** {target_language} Veuillez fournir les analyses suivantes: 1. **Traduction dans la langue cible**  - Traduire avec précision la phrase reconnue par OCR dans la langue cible 2. **Analyse des difficultés de la phrase**  - Analyser les difficultés grammaticales, lexicales et de compréhension dans la phrase 3. **Analyse contextuelle**  - Analyser la signification et l'usage de la phrase dans des contextes spécifiques 4. **Explication de l'usage**  - Expliquer en détail la structure grammaticale, le temps, la voix et autres caractéristiques d'usage de la phrase 5. **Expressions connexes**  - Fournir des expressions similaires et des phrases d'exemple pratiques **Important: Veuillez répondre dans la langue cible avec un formatage clair et lisible.**"
        case "es":
            return "Por favor, proporcione una explicación y análisis detallados de la siguiente oración reconocida por OCR en el idioma objetivo usando formato Markdown: **Oración original:** _\"{sentence}\"_（Resultado de reconocimiento OCR）**Idioma objetivo:** {target_language} Por favor, proporcione los siguientes análisis: 1. **Traducción al idioma objetivo**  - Traducir con precisión la oración reconocida por OCR al idioma objetivo 2. **Análisis de dificultades de la oración**  - Analizar dificultades gramaticales, de vocabulario y de comprensión en la oración 3. **Análisis contextual**  - Analizar el significado y uso de la oración en contextos específicos 4. **Explicación del uso**  - Explicar en detalle la estructura gramatical, tiempo, voz y otras características de uso de la oración 5. **Expresiones relacionadas**  - Proporcionar expresiones similares y oraciones de ejemplo prácticas **Importante: Por favor, responda en el idioma objetivo con formato claro y legible.**"
        case "zh-TW":
            return "請用目標語言對以下OCR識別的句子進行詳細解釋和分析，請用Markdown格式返回分析結果：**原始句子:** _\"{sentence}\"_（OCR識別結果）**目標語言:** {target_language}請提供以下分析內容：1. **目標語言翻譯**  - 將OCR識別的句子準確翻譯成目標語言2. **句子難點解析**  - 分析句子中的語法難點、詞彙難點、理解難點3. **語境分析**  - 分析句子在特定語境下的含義和用法4. **用法說明**  - 詳細說明句子的語法結構、時態、語態等用法特點5. **相關表達**  - 提供相似表達和實用例句**重要：請務必用目標語言回答，格式要清晰易讀。**"
        default:
            return "请用目标语言对以下OCR识别的句子进行详细解释和分析，请用Markdown格式返回分析结果：**原始句子:** _\"{sentence}\"_（OCR识别结果）请提供以下分析内容：1. **目标语言翻译**  - 将OCR识别的句子准确翻译成目标语言2. **句子难点解析**  - 分析句子中的语法难点、词汇难点、理解难点3. **语境分析**  - 分析句子在特定语境下的含义和用法4. **用法说明**  - 详细说明句子的语法结构、时态、语态等用法特点5. **相关表达**  - 提供相似表达和实用例句请用目标语言回答，格式要清晰易读。"
        }
    }
    
    private func getDefaultAPIConfig() -> (url: String, model: String, temperature: Double, maxTokens: Int) {
        return (
            url: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            model: "glm-4-flash",
            temperature: 0.7,
            maxTokens: 2000
        )
    }
}
