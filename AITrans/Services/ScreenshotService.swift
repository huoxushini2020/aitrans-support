//
//  ScreenshotService.swift
//  AITrans
//
//  Created by LEO on 14/9/2568 BE.
//

import AppKit
import Vision
import CoreGraphics

/// 统一的截图服务，管理所有截图操作
class ScreenshotService: ObservableObject {
    static let shared: ScreenshotService = ScreenshotService()
    
    private init() {}
    
    /// 截图来源枚举
    enum ScreenshotSource: String {
        case statusBar = "StatusBar"
        case floatingQuickIcon = "FloatingQuickIcon"
        case floatingResultWindow = "FloatingResultWindow"
        case keyboardShortcut = "KeyboardShortcut"
    }
    
    /// 开始截图操作
    /// - Parameter source: 截图来源
    func startScreenshotCapture(source: ScreenshotSource) {
        print("🟢 ScreenshotService: 开始截图操作，来源: \(source.rawValue)")
        
        // 检查权限
        guard checkScreenRecordingPermission() else {
            print("🔴 ScreenshotService: 屏幕录制权限检查失败")
            print("🔴 ScreenshotService: 请检查系统偏好设置 > 安全性与隐私 > 屏幕录制权限")
            showPermissionAlert()
            return
        }
        print("🟢 ScreenshotService: 屏幕录制权限检查通过")
        
        // 截图时只隐藏AI面板，保持浮动窗口可见
        print("ScreenshotService: 截图时隐藏AI面板，保持窗口可见")
        if let currentWindow = FloatingResultWindowManager.shared.getCurrentWindow() {
            currentWindow.hideAIDetailExplanationPanel()
        }
        
        // 使用screencapture命令截图
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // -i 交互式选择区域，-c 复制到剪贴板
        
        let pipe = Pipe()
        task.standardError = pipe // screencapture的输出通常在stderr
        
        task.terminationHandler = { process in
            print("ScreenshotService: screencapture进程结束，退出码: \(process.terminationStatus)")
            if process.terminationStatus == 0 {
                // 截图成功，从剪贴板获取图片
                DispatchQueue.main.async {
                    print("ScreenshotService: 尝试从剪贴板获取图片...")
                    if let clipboard = NSPasteboard.general.data(forType: .tiff),
                       let image = NSImage(data: clipboard) {
                        print("ScreenshotService: 成功获取剪贴板图片，开始OCR识别")
                        self.performOCR(on: image, source: source)
                    } else {
                        print("ScreenshotService: 剪贴板中没有图片")
                    }
                }
            } else {
                print("ScreenshotService: 截图失败，退出码: \(process.terminationStatus)")
                // 处理用户取消截图的情况
                if process.terminationReason == .exit && process.terminationStatus == 1 {
                    print("ScreenshotService: 用户取消了截图操作。")
                }
            }
        }
        
        task.launch()
    }
    
    /// 检查屏幕录制权限
    private func checkScreenRecordingPermission() -> Bool {
        let screenCapturePermission = CGPreflightScreenCaptureAccess()
        return screenCapturePermission
    }
    
    /// 显示权限提示对话框
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = LocalizationManager.localized("screen_recording_permission_required")
            alert.informativeText = LocalizationManager.localized("screen_recording_permission_description")
            alert.addButton(withTitle: LocalizationManager.localized("open_system_preferences"))
            alert.addButton(withTitle: LocalizationManager.localized("cancel"))
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 打开系统偏好设置
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
    
    /// 执行OCR识别
    /// - Parameters:
    ///   - image: 要识别的图片
    ///   - source: 截图来源
    private func performOCR(on image: NSImage, source: ScreenshotSource) {
        print("ScreenshotService: 开始OCR处理，来源: \(source.rawValue)")
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("ScreenshotService: 无法将NSImage转换为CGImage")
            return
        }
        
        print("ScreenshotService: 成功转换为CGImage，开始Vision识别")
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("ScreenshotService: OCR识别错误: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("ScreenshotService: OCR识别结果为空")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // 原始多行文本
            let multiLineText = recognizedStrings.joined(separator: "\n")
            print("ScreenshotService: OCR识别结果(多行): \(multiLineText)")
            
            // 将多行文本转换为一行，用空格连接
            let singleLineText = self.convertToSingleLine(multiLineText)
            print("ScreenshotService: OCR识别结果(一行): \(singleLineText)")
            
            DispatchQueue.main.async {
                // 检查是否识别出文本
                if singleLineText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // 没有识别出文本，显示提醒
                    self.showFloatingResultWindow(text: "⚠️ \(LocalizationManager.localized("no_text_detected"))")
                } else {
                    // 将识别的文字复制到剪贴板
                    self.copyTextToClipboard(singleLineText)
                    
                    // 显示弹出窗口
                    self.showFloatingResultWindow(text: singleLineText)
                }
            }
        }
        
        // 设置识别参数
        request.recognitionLevel = .accurate  // 高精度识别
        request.usesLanguageCorrection = true // 启用语言纠正
        
        // 根据用户选择的源语言设置OCR识别语言
        if let sourceLanguageCode = getCurrentSourceLanguageCode() {
            // 用户指定了具体语言，使用该语言进行识别
            request.automaticallyDetectsLanguage = false
            request.recognitionLanguages = [mapToOCRLanguageCode(sourceLanguageCode)]
            print("ScreenshotService: 使用指定语言进行OCR识别: \(sourceLanguageCode) -> \(mapToOCRLanguageCode(sourceLanguageCode))")
        } else {
            // 用户未指定语言，使用自动检测
            request.automaticallyDetectsLanguage = true
            print("ScreenshotService: 使用自动语言检测进行OCR识别")
        }
        
        // 执行识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("ScreenshotService: OCR识别执行失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clipboard Operations
    
    private func copyTextToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("📋 ScreenshotService: 已将识别文字复制到剪贴板: \(text)")
    }
    
    /// 显示浮动结果窗口
    /// - Parameter text: 要显示的文本
    private func showFloatingResultWindow(text: String) {
        // 获取当前鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        print("ScreenshotService: 准备显示结果窗口，文本: \(text), 鼠标位置: \(mouseLocation)")
        
        // 通过FloatingResultWindowManager显示结果
        FloatingResultWindowManager.shared.showResultWindow(text: text)
    }
    
    /// 将多行文本转换为单行文本
    /// - Parameter multiLineText: 多行文本
    /// - Returns: 单行文本
    private func convertToSingleLine(_ multiLineText: String) -> String {
        // 将换行符替换为空格，并清理多余的空格
        let singleLine = multiLineText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return singleLine
    }
    
    /// 获取当前源语言代码
    /// - Returns: 源语言代码
    private func getCurrentSourceLanguageCode() -> String? {
        return UserDefaults.standard.string(forKey: "AITransSourceLanguageCode")
    }
    
    /// 将翻译语言代码映射为OCR语言代码
    /// - Parameter translationCode: 翻译语言代码
    /// - Returns: OCR语言代码
    private func mapToOCRLanguageCode(_ translationCode: String) -> String {
        let mapping: [String: String] = [
            "en": "en-US",
            "zh": "zh-Hans",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "fr": "fr-FR",
            "de": "de-DE",
            "es": "es-ES",
            "it": "it-IT",
            "pt": "pt-BR",
            "ru": "ru-RU",
            "ar": "ar-SA",
            "hi": "hi-IN",
            "th": "th-TH",
            "vi": "vi-VN"
        ]
        return mapping[translationCode] ?? "en-US"
    }
}
