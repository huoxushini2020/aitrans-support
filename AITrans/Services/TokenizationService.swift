//
//  TokenizationService.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation
import NaturalLanguage

// MARK: - 分词结果模型
struct TokenItem {
    let text: String
    let range: NSRange
    let tokenType: NLTokenUnit
    let isWord: Bool  // 是否为单词（用于高亮判断）
    let language: String  // 语言代码
    let partOfSpeech: String?  // 词性信息
}

// MARK: - 分词服务
class TokenizationService {
    static let shared: TokenizationService = TokenizationService()
    
    private init() {}
    
    /// 对文本进行分词
    /// - Parameter text: 要分词的文本
    /// - Returns: 分词结果数组，如果没有单词则返回空数组
    func tokenize(_ text: String) -> [TokenItem] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        // 检测文本语言
        let language = detectLanguage(text)
        
        // 使用NLTagger获取词性信息
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var tokens: [TokenItem] = []
        var lastIndex = text.startIndex
        
        // 先获取所有单词
        var wordRanges: [(Range<String.Index>, String)] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, attributes in
            let tokenText = String(text[tokenRange])
            wordRanges.append((tokenRange, tokenText))
            return true
        }
        
        // 如果没有单词，直接返回空数组
        if wordRanges.isEmpty {
            return []
        }
        
        // 处理单词和标点符号
        for (wordRange, wordText) in wordRanges {
            // 添加单词前的标点符号
            if lastIndex < wordRange.lowerBound {
                let punctuationRange = lastIndex..<wordRange.lowerBound
                let punctuationText = String(text[punctuationRange])
                if !punctuationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let nsRange = NSRange(punctuationRange, in: text)
                    let tokenItem = TokenItem(
                        text: punctuationText,
                        range: nsRange,
                        tokenType: .word,
                        isWord: false,  // 标点符号不高亮
                        language: language,
                        partOfSpeech: nil  // 标点符号没有词性
                    )
                    tokens.append(tokenItem)
                }
            }
            
            // 获取单词的词性
            let partOfSpeech = getPartOfSpeech(for: wordText, in: wordRange, tagger: tagger)
            
            // 添加单词
            let nsRange = NSRange(wordRange, in: text)
            let tokenItem = TokenItem(
                text: wordText,
                range: nsRange,
                tokenType: .word,
                isWord: true,  // 单词可以高亮
                language: language,
                partOfSpeech: partOfSpeech
            )
            tokens.append(tokenItem)
            
            lastIndex = wordRange.upperBound
        }
        
        // 添加最后的标点符号
        if lastIndex < text.endIndex {
            let punctuationRange = lastIndex..<text.endIndex
            let punctuationText = String(text[punctuationRange])
            if !punctuationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let nsRange = NSRange(punctuationRange, in: text)
                let tokenItem = TokenItem(
                    text: punctuationText,
                    range: nsRange,
                    tokenType: .word,
                    isWord: false,  // 标点符号不高亮
                    language: language,
                    partOfSpeech: nil  // 标点符号没有词性
                )
                tokens.append(tokenItem)
            }
        }
        
        return tokens
    }
    
    /// 获取单词的词性
    /// - Parameters:
    ///   - word: 单词文本
    ///   - range: 单词在原文中的范围
    ///   - tagger: NLTagger实例
    /// - Returns: 词性字符串
    private func getPartOfSpeech(for word: String, in range: Range<String.Index>, tagger: NLTagger) -> String? {
        // 获取词性标签
        let tags = tagger.tags(in: range, unit: .word, scheme: .lexicalClass)
        
        guard let (tag, _) = tags.first, let unwrappedTag = tag else { return nil }
        
        // 将词性标签转换为英文缩写
        return convertPartOfSpeechToAbbreviation(unwrappedTag)
    }
    
    /// 将词性标签转换为英文缩写
    /// - Parameter tag: 词性标签
    /// - Returns: 英文词性缩写
    private func convertPartOfSpeechToAbbreviation(_ tag: NLTag) -> String? {
        switch tag {
        case .noun:
            return "n."
        case .verb:
            return "v."
        case .adjective:
            return "adj."
        case .adverb:
            return "adv."
        case .pronoun:
            return "pron."
        case .determiner:
            return "det."
        case .particle:
            return "part."
        case .preposition:
            return "prep."
        case .number:
            return "num."
        case .conjunction:
            return "conj."
        case .interjection:
            return "interj."
        case .classifier:
            return "class."
        case .idiom:
            return "idiom"
        case .otherWord:
            return "other"
        case .sentenceTerminator:
            return "punct."
        case .openQuote:
            return "quote"
        case .closeQuote:
            return "quote"
        case .openParenthesis:
            return "paren"
        case .closeParenthesis:
            return "paren"
        case .wordJoiner:
            return "join"
        case .dash:
            return "dash"
        case .otherPunctuation:
            return "punct."
        case .paragraphBreak:
            return "para"
        case .otherWhitespace:
            return "space"
        case .personalName:
            return "name"
        case .placeName:
            return "place"
        case .organizationName:
            return "org"
        case .whitespace:
            return "space"
        default:
            return "unknown"
        }
    }
    
    /// 对文本进行句子分割
    /// - Parameter text: 要分割的文本
    /// - Returns: 句子数组
    func splitIntoSentences(_ text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, attributes in
            let sentence = String(text[tokenRange])
            sentences.append(sentence)
            return true
        }
        
        return sentences
    }
    
    /// 检测文本语言
    /// - Parameter text: 要检测的文本
    /// - Returns: 语言代码
    func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else { return "en" }
        
        switch language {
        case .simplifiedChinese:
            return "zh-Hans"
        case .traditionalChinese:
            return "zh-Hant"
        case .english:
            return "en"
        case .japanese:
            return "ja"
        case .korean:
            return "ko"
        case .french:
            return "fr"
        case .german:
            return "de"
        case .spanish:
            return "es"
        case .italian:
            return "it"
        case .portuguese:
            return "pt"
        case .russian:
            return "ru"
        case .arabic:
            return "ar"
        case .hindi:
            return "hi"
        case .thai:
            return "th"
        case .vietnamese:
            return "vi"
        default:
            return "en"
        }
    }
}
