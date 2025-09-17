import Foundation

// MARK: - 音标转换服务
class PhoneticService {
    static let shared: PhoneticService = PhoneticService()
    
    // ARPAbet 到 IPA 的映射表
    private let arpabetToIPA: [String: String] = [
        // 元音
        "AA": "ɑ", "AE": "æ", "AH": "ʌ", "AO": "ɔ", "AW": "aʊ", "AY": "aɪ",
        "EH": "ɛ", "ER": "ɜr", "EY": "eɪ", "IH": "ɪ", "IY": "i", "OW": "oʊ",
        "OY": "ɔɪ", "UH": "ʊ", "UW": "u",
        
        // 辅音
        "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "F": "f", "G": "ɡ",
        "HH": "h", "JH": "dʒ", "K": "k", "L": "l", "M": "m", "N": "n",
        "NG": "ŋ", "P": "p", "R": "r", "S": "s", "SH": "ʃ", "T": "t",
        "TH": "θ", "V": "v", "W": "w", "Y": "j", "Z": "z", "ZH": "ʒ",
        
        // 重音符号
        "0": "", // 无重音
        "1": "ˈ", // 主重音
        "2": "ˌ"  // 次重音
    ]
    
    // 重音标记
    private let stressMarkers = ["0", "1", "2"]
    
    // CMUdict 词典数据（从文件加载）
    private var cmudict: [String: [String]] = [:]
    private var isLoaded = false
    
    private init() {
        loadCMUDict()
    }
    
    // MARK: - 私有方法
    
    /// 从cmudict.dict文件加载词典数据
    private func loadCMUDict() {
        guard let path = Bundle.main.path(forResource: "cmudict", ofType: "dict") else {
            print("PhoneticService: 找不到cmudict.dict文件")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix(";;;") {
                    continue
                }
                
                let components = trimmedLine.components(separatedBy: .whitespaces)
                if components.count >= 2 {
                    let word = components[0].lowercased()
                    let phonemes = Array(components[1...])
                    cmudict[word] = phonemes
                }
            }
            
            isLoaded = true
            print("PhoneticService: 成功加载 \(cmudict.count) 个单词的音标数据")
            
        } catch {
            print("PhoneticService: 加载cmudict.dict文件失败: \(error)")
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取单词的音标（IPA格式）
    /// - Parameter word: 要查询的单词
    /// - Returns: IPA音标字符串，如果找不到则返回nil
    func getPhoneticTranscription(for word: String) -> String? {
        guard isLoaded else {
            print("PhoneticService: 词典尚未加载完成")
            return nil
        }
        
        let cleanWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 从CMUdict查找ARPAbet音标
        guard let arpabetPhonemes = cmudict[cleanWord] else {
            return nil
        }
        
        // 转换为IPA格式
        return convertARPAbetToIPA(arpabetPhonemes)
    }
    
    /// 检查单词是否在词典中
    /// - Parameter word: 要检查的单词
    /// - Returns: 是否找到该单词
    func hasPhoneticData(for word: String) -> Bool {
        guard isLoaded else {
            return false
        }
        
        let cleanWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return cmudict[cleanWord] != nil
    }
    
    // MARK: - 私有方法
    
    /// 将ARPAbet音标转换为IPA格式
    /// - Parameter arpabetPhonemes: ARPAbet音标数组
    /// - Returns: IPA格式的音标字符串
    private func convertARPAbetToIPA(_ arpabetPhonemes: [String]) -> String {
        var ipaString = ""
        
        for phoneme in arpabetPhonemes {
            // 处理重音标记
            let cleanPhoneme = phoneme.replacingOccurrences(of: "[0-2]", with: "", options: .regularExpression)
            let stress = phoneme.last?.isNumber == true ? String(phoneme.last!) : "0"
            
            // 转换为IPA
            if let ipaSymbol = arpabetToIPA[cleanPhoneme] {
                // 添加重音标记
                let stressedSymbol = addStressToIPA(ipaSymbol, stress: stress)
                ipaString += stressedSymbol
            } else {
                // 如果找不到映射，保留原始符号
                ipaString += phoneme
            }
        }
        
        return "/\(ipaString)/"
    }
    
    /// 为IPA符号添加重音标记
    /// - Parameters:
    ///   - symbol: IPA符号
    ///   - stress: 重音级别 ("0", "1", "2")
    /// - Returns: 带重音标记的IPA符号
    private func addStressToIPA(_ symbol: String, stress: String) -> String {
        switch stress {
        case "1": // 主重音
            return "ˈ\(symbol)"
        case "2": // 次重音
            return "ˌ\(symbol)"
        default: // "0" 无重音
            return symbol
        }
    }
}

// MARK: - 扩展方法
extension PhoneticService {
    
    /// 获取单词的详细音标信息
    /// - Parameter word: 要查询的单词
    /// - Returns: 包含ARPAbet和IPA的音标信息
    func getDetailedPhoneticInfo(for word: String) -> PhoneticInfo? {
        guard isLoaded else {
            print("PhoneticService: 词典尚未加载完成")
            return nil
        }
        
        let cleanWord = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let arpabetPhonemes = cmudict[cleanWord] else {
            return nil
        }
        
        let ipaTranscription = convertARPAbetToIPA(arpabetPhonemes)
        
        return PhoneticInfo(
            word: cleanWord,
            arpabet: arpabetPhonemes,
            ipa: ipaTranscription
        )
    }
}

// MARK: - 音标信息结构体
struct PhoneticInfo {
    let word: String
    let arpabet: [String]
    let ipa: String
    
    var displayText: String {
        return "\(word) \(ipa)"
    }
}
