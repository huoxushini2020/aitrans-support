import Foundation

// MARK: - 中文拼音转换服务
class PinyinService {
    static let shared: PinyinService = PinyinService()
    
    private init() {
        loadPinyinData()
    }
    
    // 拼音到IPA的映射表（从CSV文件加载）
    private var pinyinToIPA: [String: String] = [:]
    private var isLoaded = false
    
    /// 从pinyinipa.csv文件加载拼音数据
    private func loadPinyinData() {
        guard let path = Bundle.main.path(forResource: "pinyinipa", ofType: "csv") else {
            print("PinyinService: 找不到pinyinipa.csv文件")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for (index, line) in lines.enumerated() {
                if index == 0 || line.isEmpty { continue } // 跳过标题行和空行
                
                let components = line.components(separatedBy: ",")
                if components.count >= 2 {
                    let pinyin = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let ipa = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 移除IPA中的引号
                    let cleanIPA = ipa.replacingOccurrences(of: "\"", with: "")
                    
                    // 只存储一声（阴平）的映射，作为基础拼音
                    if components.count >= 3 {
                        let tone = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                        if tone.contains("一声") || tone.contains("阴平") {
                            pinyinToIPA[pinyin] = cleanIPA
                        }
                    } else {
                        // 如果没有声调信息，直接存储
                        pinyinToIPA[pinyin] = cleanIPA
                    }
                }
            }
            
            isLoaded = true
            print("PinyinService: 拼音数据加载完成，包含 \(pinyinToIPA.count) 个音节")
        } catch {
            print("PinyinService: 加载pinyinipa.csv失败: \(error)")
        }
    }
    
    /// 获取中文字符的拼音
    /// - Parameter text: 中文字符
    /// - Returns: 拼音字符串，如果找不到则返回nil
    func getPinyin(for text: String) -> String? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否包含中文字符
        guard containsChinese(cleanText) else {
            return nil
        }
        
        // 使用CFStringTransform进行拼音转换
        let mutableString = NSMutableString(string: cleanText)
        let success = CFStringTransform(mutableString, nil, kCFStringTransformMandarinLatin, false)
        
        if success {
            let pinyin = String(mutableString)
            return formatPinyin(pinyin)
        }
        
        return nil
    }
    
    /// 获取中文的详细拼音信息
    /// - Parameter text: 中文字符
    /// - Returns: 包含拼音和声调的详细信息
    func getDetailedPinyinInfo(for text: String) -> PinyinInfo? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard containsChinese(cleanText) else {
            return nil
        }
        
        // 使用CFStringTransform获取带声调的拼音
        let mutableString = NSMutableString(string: cleanText)
        let success = CFStringTransform(mutableString, nil, kCFStringTransformMandarinLatin, false)
        
        if success {
            let pinyinWithTones = String(mutableString)
            let pinyinWithoutTones = removeToneMarks(pinyinWithTones)
            
            return PinyinInfo(
                text: cleanText,
                pinyin: pinyinWithoutTones,
                pinyinWithTones: pinyinWithTones
            )
        }
        
        return nil
    }
    
    /// 获取拼音的IPA音标
    /// - Parameter pinyin: 拼音字符串
    /// - Returns: IPA音标，如果找不到则返回nil
    func getIPA(for pinyin: String) -> String? {
        guard isLoaded else {
            print("PinyinService: 拼音数据尚未加载完成")
            return nil
        }
        
        let cleanPinyin = pinyin.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return pinyinToIPA[cleanPinyin]
    }
    
    /// 检查文本是否包含中文字符
    /// - Parameter text: 要检查的文本
    /// - Returns: 是否包含中文字符
    func containsChinese(_ text: String) -> Bool {
        let chineseRegex = try! NSRegularExpression(pattern: "[\\u4e00-\\u9fff]")
        let range = NSRange(location: 0, length: text.utf16.count)
        return chineseRegex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    /// 格式化拼音（移除声调符号）
    /// - Parameter pinyin: 带声调的拼音
    /// - Returns: 格式化后的拼音
    private func formatPinyin(_ pinyin: String) -> String {
        return removeToneMarks(pinyin)
    }
    
    /// 移除声调符号
    /// - Parameter pinyin: 带声调的拼音
    /// - Returns: 不带声调的拼音
    private func removeToneMarks(_ pinyin: String) -> String {
        let toneMarks = ["̄", "́", "̌", "̀", "̇"]
        var result = pinyin
        for mark in toneMarks {
            result = result.replacingOccurrences(of: mark, with: "")
        }
        return result
    }
}

// MARK: - 拼音信息结构
struct PinyinInfo {
    let text: String
    let pinyin: String
    let pinyinWithTones: String
}
