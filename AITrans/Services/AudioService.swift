//
//  AudioService.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Foundation
import AVFoundation
import NaturalLanguage

// MARK: - 统一声音服务
class AudioService {
    static let shared: AudioService = AudioService()
    
    // MARK: - 子服务
    private let playbackService = AudioPlaybackService.shared
    private let phoneticService = PhoneticService.shared
    
    // MARK: - 代理
    weak var delegate: AudioServiceDelegate?
    
    private init() {
        // 设置播放服务的代理
        playbackService.delegate = self
    }
    
    // MARK: - 公共接口
    
    /// 播放文本语音
    /// - Parameter text: 要播放的文本
    func playText(_ text: String) {
        playbackService.playText(text)
    }
    
    /// 播放文本语音（带上下文）
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - context: 上下文文本（用于更准确的语言检测）
    func playText(_ text: String, context: String?) {
        playbackService.playText(text, context: context)
    }
    
    /// 停止播放
    func stopPlayback() {
        playbackService.stopPlayback()
    }
    
    /// 暂停播放
    func pausePlayback() {
        playbackService.pausePlayback()
    }
    
    /// 继续播放
    func resumePlayback() {
        playbackService.resumePlayback()
    }
    
    /// 检查是否正在播放
    var isCurrentlyPlaying: Bool {
        return playbackService.isCurrentlyPlaying
    }
    
    /// 获取单词的音标（IPA格式）
    /// - Parameter word: 要查询的单词
    /// - Returns: IPA音标字符串，如果找不到则返回nil
    func getPhoneticTranscription(for word: String) -> String? {
        return phoneticService.getPhoneticTranscription(for: word)
    }
    
    /// 检查单词是否在音标词典中
    /// - Parameter word: 要检查的单词
    /// - Returns: 是否找到该单词
    func hasPhoneticData(for word: String) -> Bool {
        return phoneticService.hasPhoneticData(for: word)
    }
    
    /// 获取单词的详细音标信息
    /// - Parameter word: 要查询的单词
    /// - Returns: 包含ARPAbet和IPA的音标信息
    func getDetailedPhoneticInfo(for word: String) -> PhoneticInfo? {
        return phoneticService.getDetailedPhoneticInfo(for: word)
    }
    
    /// 播放单词并显示音标信息
    /// - Parameters:
    ///   - word: 要播放的单词
    ///   - showPhonetic: 是否显示音标信息
    func playWordWithPhonetic(_ word: String, showPhonetic: Bool = true) {
        // 播放单词
        playText(word)
        
        // 如果请求显示音标信息
        if showPhonetic {
            if let phoneticInfo = getDetailedPhoneticInfo(for: word) {
                print("🔊 播放单词: \(phoneticInfo.displayText)")
            } else {
                print("🔊 播放单词: \(word) (无音标数据)")
            }
        }
    }
}

// MARK: - AudioPlaybackServiceDelegate
extension AudioService: AudioPlaybackServiceDelegate {
    func audioPlaybackDidStart() {
        delegate?.audioServiceDidStart()
    }
    
    func audioPlaybackDidFinish() {
        delegate?.audioServiceDidFinish()
    }
    
    func audioPlaybackDidStop() {
        delegate?.audioServiceDidStop()
    }
    
    func audioPlaybackDidPause() {
        delegate?.audioServiceDidPause()
    }
    
    func audioPlaybackDidResume() {
        delegate?.audioServiceDidResume()
    }
    
    func audioPlaybackDidCancel() {
        delegate?.audioServiceDidCancel()
    }
}

// MARK: - AudioServiceDelegate
protocol AudioServiceDelegate: AnyObject {
    /// 播放开始
    func audioServiceDidStart()
    
    /// 播放完成
    func audioServiceDidFinish()
    
    /// 播放停止
    func audioServiceDidStop()
    
    /// 播放暂停
    func audioServiceDidPause()
    
    /// 播放继续
    func audioServiceDidResume()
    
    /// 播放取消
    func audioServiceDidCancel()
}
