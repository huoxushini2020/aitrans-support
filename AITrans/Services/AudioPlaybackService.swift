//
//  AudioPlaybackService.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation
import AVFoundation
import NaturalLanguage

// MARK: - AudioPlaybackService

class AudioPlaybackService: NSObject {
    static let shared: AudioPlaybackService = AudioPlaybackService()
    
    // MARK: - Properties
    
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var isPlaying: Bool = false
    
    // MARK: - Delegate
    
    weak var delegate: AudioPlaybackServiceDelegate?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupSpeechSynthesizer()
    }
    
    // MARK: - Setup
    
    private func setupSpeechSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// 播放文本语音
    /// - Parameter text: 要播放的文本
    func playText(_ text: String) {
        playText(text, context: nil)
    }
    
    /// 播放文本语音（带上下文）
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - context: 上下文文本（用于更准确的语言检测）
    func playText(_ text: String, context: String?) {
        guard !text.isEmpty else { return }
        
        // 检查是否为单字母单词
        let cleanText = cleanTextForSpeech(text)
        let isSingleLetter = cleanText.count == 1 && cleanText.rangeOfCharacter(from: CharacterSet.letters) != nil
        
        if isSingleLetter {
            // 使用截断播放方法
            createTruncatedSpeechUtterance(text: text, context: context)
        } else {
            // 使用普通播放方法
            playTextNormally(text: text, context: context)
        }
    }
    
    /// 普通播放方法
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - context: 上下文文本
    private func playTextNormally(text: String, context: String?) {
        // 停止当前播放
        stopPlayback()
        
        // 清理文本，确保只朗读纯文本内容
        let cleanText = cleanTextForSpeech(text)
        
        // 创建语音合成
        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7  // 设置为较快的语速
        utterance.volume = 1.0
        
        // 在后台线程检测语言，避免优先级反转
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 优先使用上下文进行语言检测，提高准确性
            let language = self.detectLanguage(for: cleanText, context: context)
            
            // 回到主线程设置语音并开始播放
            DispatchQueue.main.async {
                if let language = language {
                    utterance.voice = AVSpeechSynthesisVoice(language: language)
                }
                
                // 开始播放
                self.speechSynthesizer?.speak(utterance)
                self.isPlaying = true
                
                // 通知代理
                self.delegate?.audioPlaybackDidStart()
            }
        }
    }
    
    /// 停止播放
    func stopPlayback() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        isPlaying = false
        delegate?.audioPlaybackDidStop()
    }
    
    /// 暂停播放
    func pausePlayback() {
        speechSynthesizer?.pauseSpeaking(at: .immediate)
        isPlaying = false
        delegate?.audioPlaybackDidPause()
    }
    
    /// 继续播放
    func resumePlayback() {
        speechSynthesizer?.continueSpeaking()
        isPlaying = true
        delegate?.audioPlaybackDidResume()
    }
    
    /// 检查是否正在播放
    var isCurrentlyPlaying: Bool {
        return isPlaying
    }
    
    // MARK: - Text Processing
    
    /// 清理文本，确保只朗读纯文本内容
    /// - Parameter text: 原始文本
    /// - Returns: 清理后的文本
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleanText = text
        
        // 特殊处理单字母单词，避免被识别为字母
        cleanText = optimizeSingleLetterWords(cleanText)
        
        // 移除标点符号（不朗读标点符号）
        let punctuationPattern = "[\\p{P}\\p{S}]+"
        cleanText = cleanText.replacingOccurrences(of: punctuationPattern, with: " ", options: .regularExpression)
        
        // 移除多余的空格和换行符
        cleanText = cleanText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 移除首尾空格
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除特殊字符
        cleanText = cleanText.replacingOccurrences(of: "[\\r\\n\\t]+", with: " ", options: .regularExpression)
        
        // 确保文本不为空
        if cleanText.isEmpty {
            return text // 如果清理后为空，返回原始文本
        }
        
        return cleanText
    }
    
    /// 优化单字母单词，避免被识别为字母
    /// - Parameter text: 原始文本
    /// - Returns: 优化后的文本
    private func optimizeSingleLetterWords(_ text: String) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为单字母单词
        guard trimmedText.count == 1 else { return text }
        
        // 检查是否为字母
        guard trimmedText.rangeOfCharacter(from: CharacterSet.letters) != nil else { return text }
        
        // 常见的单字母单词列表
        let singleLetterWords: [String: String] = [
            "I": "I",           // 英语：我
            "a": "a",           // 英语：一个
            "A": "A",           // 英语：一个（大写）
            "i": "i",           // 英语：我（小写）
            "o": "o",           // 英语：哦
            "O": "O",           // 英语：哦（大写）
            "u": "you",         // 英语：你（网络用语）
            "U": "you",         // 英语：你（网络用语，大写）
            "r": "are",         // 英语：是（网络用语）
            "R": "are",         // 英语：是（网络用语，大写）
            "c": "see",         // 英语：看（网络用语）
            "C": "see",         // 英语：看（网络用语，大写）
            "y": "why",         // 英语：为什么（网络用语）
            "Y": "why",         // 英语：为什么（网络用语，大写）
            "n": "and",         // 英语：和（网络用语）
            "N": "and",         // 英语：和（网络用语，大写）
            "b": "be",          // 英语：是（网络用语）
            "B": "be",          // 英语：是（网络用语，大写）
            "t": "to",          // 英语：到（网络用语）
            "T": "to",          // 英语：到（网络用语，大写）
            "f": "for",         // 英语：为了（网络用语）
            "F": "for",         // 英语：为了（网络用语，大写）
            "w": "with",        // 英语：和（网络用语）
            "W": "with",        // 英语：和（网络用语，大写）
            "h": "have",        // 英语：有（网络用语）
            "H": "have",        // 英语：有（网络用语，大写）
            "m": "am",          // 英语：是（网络用语）
            "M": "am",          // 英语：是（网络用语，大写）
            "s": "is",          // 英语：是（网络用语）
            "S": "is",          // 英语：是（网络用语，大写）
            "d": "do",          // 英语：做（网络用语）
            "D": "do",          // 英语：做（网络用语，大写）
            "l": "will",        // 英语：将（网络用语）
            "L": "will",        // 英语：将（网络用语，大写）
            "g": "go",          // 英语：去（网络用语）
            "G": "go",          // 英语：去（网络用语，大写）
            "k": "okay",        // 英语：好的（网络用语）
            "K": "okay",        // 英语：好的（网络用语，大写）
            "j": "just",        // 英语：只是（网络用语）
            "J": "just",        // 英语：只是（网络用语，大写）
            "p": "please",      // 英语：请（网络用语）
            "P": "please",      // 英语：请（网络用语，大写）
            "v": "very",        // 英语：非常（网络用语）
            "V": "very",        // 英语：非常（网络用语，大写）
            "x": "ex",          // 英语：前（网络用语）
            "X": "ex",          // 英语：前（网络用语，大写）
            "z": "zero",        // 英语：零（网络用语）
            "Z": "zero"         // 英语：零（网络用语，大写）
        ]
        
        // 查找对应的完整单词
        if let fullWord = singleLetterWords[trimmedText] {
            print("🔤 单字母单词优化: '\(trimmedText)' → '\(fullWord)'")
            return fullWord
        }
        
        // 如果没有找到对应的单词，返回原始文本
        return text
    }
    
    /// 处理单字母单词的截断读音，强制单词发音
    /// - Parameter text: 清理后的文本
    /// - Returns: 处理后的文本
    private func processSingleLetterWordsForSpeech(_ text: String) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为单字母单词
        guard trimmedText.count == 1 else { 
            print("🔤 多字母单词，保持原样: '\(trimmedText)'")
            return text 
        }
        
        // 检查是否为字母
        guard trimmedText.rangeOfCharacter(from: CharacterSet.letters) != nil else { 
            print("🔤 非字母字符，保持原样: '\(trimmedText)'")
            return text 
        }
        
        // 根据不同的单字母单词选择最合适的处理方法
        let processedText = getOptimalSpeechText(for: trimmedText)
        
        print("🔤 单字母单词截断读音处理: '\(trimmedText)' → '\(processedText)'")
        return processedText
    }
    
    /// 获取单字母单词的最优发音文本
    /// - Parameter letter: 单字母
    /// - Returns: 处理后的发音文本
    private func getOptimalSpeechText(for letter: String) -> String {
        switch letter.lowercased() {
        case "i":
            // 对于 "I"，使用句子开头的方式强制单词发音
            return "I am"
        case "a":
            // 对于 "a"，使用冠词的方式
            return "a word"
        case "o":
            // 对于 "o"，使用感叹的方式
            return "oh my"
        case "u":
            // 对于 "u"，使用网络用语的方式
            return "you are"
        case "r":
            // 对于 "r"，使用动词的方式
            return "are you"
        case "c":
            // 对于 "c"，使用动词的方式
            return "see you"
        case "y":
            // 对于 "y"，使用疑问词的方式
            return "why not"
        case "n":
            // 对于 "n"，使用连词的方式
            return "and so"
        case "b":
            // 对于 "b"，使用动词的方式
            return "be good"
        case "t":
            // 对于 "t"，使用介词的方式
            return "to go"
        case "f":
            // 对于 "f"，使用介词的方式
            return "for you"
        case "w":
            // 对于 "w"，使用介词的方式
            return "with me"
        case "h":
            // 对于 "h"，使用动词的方式
            return "have fun"
        case "m":
            // 对于 "m"，使用动词的方式
            return "am here"
        case "s":
            // 对于 "s"，使用动词的方式
            return "is good"
        case "d":
            // 对于 "d"，使用动词的方式
            return "do it"
        case "l":
            // 对于 "l"，使用助动词的方式
            return "will go"
        case "g":
            // 对于 "g"，使用动词的方式
            return "go now"
        case "k":
            // 对于 "k"，使用形容词的方式
            return "okay then"
        case "j":
            // 对于 "j"，使用副词的方式
            return "just now"
        case "p":
            // 对于 "p"，使用动词的方式
            return "please do"
        case "v":
            // 对于 "v"，使用副词的方式
            return "very good"
        case "x":
            // 对于 "x"，使用前缀的方式
            return "ex good"
        case "z":
            // 对于 "z"，使用名词的方式
            return "zero one"
        default:
            // 默认方法：添加句号和空格
            return "\(letter). "
        }
    }
    
    /// 创建带截断的语音合成，只播放第一个单词
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - context: 上下文文本
    private func createTruncatedSpeechUtterance(text: String, context: String?) {
        // 停止当前播放
        stopPlayback()
        
        // 清理文本，确保只朗读纯文本内容
        let cleanText = cleanTextForSpeech(text)
        
        // 特殊处理单字母单词，使用单词截断读音方法
        let processedText = processSingleLetterWordsForSpeech(cleanText)
        
        // 创建语音合成
        let utterance = AVSpeechUtterance(string: processedText)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7  // 设置为较快的语速
        utterance.volume = 1.0
        
        // 在后台线程检测语言，避免优先级反转
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 优先使用上下文进行语言检测，提高准确性
            let language = self.detectLanguage(for: cleanText, context: context)
            
            // 回到主线程设置语音并开始播放
            DispatchQueue.main.async {
                if let language = language {
                    utterance.voice = AVSpeechSynthesisVoice(language: language)
                }
                
                // 开始播放
                self.speechSynthesizer?.speak(utterance)
                self.isPlaying = true
                
                // 通知代理
                self.delegate?.audioPlaybackDidStart()
                
                // 如果是单字母单词，在播放一半时停止
                if cleanText.count == 1 && cleanText.rangeOfCharacter(from: CharacterSet.letters) != nil {
                    self.scheduleTruncation()
                }
            }
        }
    }
    
    /// 安排语音截断
    private func scheduleTruncation() {
        // 计算截断时间（大约播放一半的时间）
        let truncationDelay = 0.3 // 300毫秒后停止
        
        DispatchQueue.main.asyncAfter(deadline: .now() + truncationDelay) { [weak self] in
            self?.stopPlayback()
            print("🔤 单字母单词发音已截断")
        }
    }
    
    // MARK: - Language Detection
    
    /// 检测文本语言
    /// - Parameters:
    ///   - text: 要检测的文本
    ///   - context: 上下文文本（用于更准确的语言检测）
    /// - Returns: 语言代码字符串
    private func detectLanguage(for text: String, context: String? = nil) -> String? {
        let recognizer = NLLanguageRecognizer()
        
        // 优先使用上下文进行语言检测，提高准确性
        let textToAnalyze = context ?? text
        recognizer.processString(textToAnalyze)
        
        guard let language = recognizer.dominantLanguage else { return nil }
        
        // 转换为AVSpeechSynthesisVoice支持的语言代码
        switch language {
        case .simplifiedChinese:
            return "zh-CN"
        case .traditionalChinese:
            return "zh-TW"
        case .english:
            return "en-US"
        case .japanese:
            return "ja-JP"
        case .korean:
            return "ko-KR"
        case .french:
            return "fr-FR"
        case .german:
            return "de-DE"
        case .spanish:
            return "es-ES"
        case .italian:
            return "it-IT"
        case .portuguese:
            return "pt-PT"
        case .russian:
            return "ru-RU"
        case .arabic:
            return "ar-SA"
        case .hindi:
            return "hi-IN"
        case .thai:
            return "th-TH"
        default:
            return "en-US" // 默认英语
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension AudioPlaybackService: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPlaying = true
        delegate?.audioPlaybackDidStart()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        delegate?.audioPlaybackDidFinish()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        delegate?.audioPlaybackDidCancel()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        isPlaying = false
        delegate?.audioPlaybackDidPause()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        isPlaying = true
        delegate?.audioPlaybackDidResume()
    }
}

// MARK: - AudioPlaybackServiceDelegate

protocol AudioPlaybackServiceDelegate: AnyObject {
    /// 播放开始
    func audioPlaybackDidStart()
    
    /// 播放完成
    func audioPlaybackDidFinish()
    
    /// 播放停止
    func audioPlaybackDidStop()
    
    /// 播放暂停
    func audioPlaybackDidPause()
    
    /// 播放继续
    func audioPlaybackDidResume()
    
    /// 播放取消
    func audioPlaybackDidCancel()
}
