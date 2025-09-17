//
//  FloatingQuickIcon.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import AppKit
import Vision
import CoreGraphics

class FloatingQuickIcon: NSView {
    private var floatingWindow: NSWindow?
    private var iconButton: NSButton!
    private var isVisible = false
    
    // 弱引用到主窗口，用于获取语言设置
    weak var mainWindow: NSWindow?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupFloatingIcon()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupFloatingIcon()
    }
    
    private func setupFloatingIcon() {
        // 创建悬浮窗口
        floatingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 60, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingWindow else { return }
        
        // 设置窗口属性
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = NSWindow.Level.floating
        window.ignoresMouseEvents = false
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        
        // 创建图标按钮
        iconButton = NSButton(frame: NSRect(x: 0, y: 0, width: 60, height: 60))
        iconButton.target = self
        iconButton.action = #selector(iconButtonClicked) // 设置点击事件
        iconButton.isBordered = false
        iconButton.wantsLayer = true
        
        // 设置右键菜单
        iconButton.menu = createContextMenu()
        
        // 设置按钮样式
        setupButtonAppearance()
        
        // 设置按钮图标
        updateButtonIcon()
        
        // 将按钮添加到窗口
        window.contentView = iconButton
        
        // 设置初始位置（屏幕左下角）
        moveToBottomLeft()
        
        // 添加鼠标跟踪区域
        setupTrackingArea()
    }
    
    private func setupButtonAppearance() {
        guard let button = iconButton else { return }
        
        button.layer?.cornerRadius = 30
        button.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        button.layer?.borderWidth = 2
        button.layer?.borderColor = NSColor.white.cgColor
        button.layer?.masksToBounds = true
        
        // 添加阴影
        button.shadow = NSShadow()
        button.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.3)
        button.shadow?.shadowOffset = NSSize(width: 0, height: 2)
        button.shadow?.shadowBlurRadius = 8
    }
    
    private func updateButtonIcon() {
        guard let button = iconButton else { return }
        
        // 使用系统图标
        let icon = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "截图OCR")
        icon?.isTemplate = true
        button.image = icon
        button.imagePosition = .imageOnly
        button.contentTintColor = .white
    }
    
    private func setupTrackingArea() {
        guard let button = iconButton else { return }
        
        let trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        button.addTrackingArea(trackingArea)
    }
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        // 关闭菜单项
        let closeItem = NSMenuItem(
            title: "关闭悬浮图标",
            action: #selector(closeIcon),
            keyEquivalent: ""
        )
        closeItem.target = self
        closeItem.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: "Close")
        closeItem.image?.isTemplate = true
        closeItem.isEnabled = true
        menu.addItem(closeItem)
        
        return menu
    }
    
    private func setupRightClickMenu() {
        // 这个方法现在不需要了，因为我们在创建按钮时直接设置了菜单
    }
    
    private func positionAtBottomRight() {
        guard let window = floatingWindow else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowSize = window.frame.size
        
        let x = screenFrame.maxX - windowSize.width - 20
        let y = screenFrame.minY + 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func closeIcon() {
        hideIcon()
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        // 鼠标悬停效果
        animateButtonScale(scale: 1.1)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        // 恢复原始大小
        animateButtonScale(scale: 1.0)
    }
    
    @objc private func iconButtonClicked() {
        // 添加点击动画反馈
        animateButtonClick()
        
        // 左键点击 - 执行截图OCR
        performScreenshotOCR()
    }
    
    override func mouseDown(with event: NSEvent) {
        // 处理鼠标按下事件
        if event.buttonNumber == 0 {
            // 左键点击 - 执行截图OCR
            performScreenshotOCR()
        } else if event.buttonNumber == 1 {
            // 右键点击 - 显示菜单
            showContextMenu(at: event.locationInWindow)
        }
    }
    
    private func showContextMenu(at location: NSPoint) {
        guard let button = iconButton, let menu = button.menu else { return }
        
        // 将窗口坐标转换为屏幕坐标
        let windowLocation = floatingWindow?.convertToScreen(NSRect(origin: location, size: NSSize.zero)).origin ?? NSPoint.zero
        
        // 显示菜单
        menu.popUp(positioning: nil, at: windowLocation, in: nil)
    }
    
    private func animateButtonScale(scale: CGFloat) {
        guard let button = iconButton else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            button.layer?.transform = CATransform3DMakeScale(scale, scale, 1.0)
        }
    }
    
    private func animateButtonClick() {
        guard let button = iconButton else { return }
        
        // 点击动画：先缩小再恢复
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            button.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1.0)
        }) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                button.layer?.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
            })
        }
    }
    
    // MARK: - 截图OCR功能
    private func performScreenshotOCR() {
        // 直接调用startScreenshotCapture，它内部会进行权限检查
        startScreenshotCapture()
    }
    
    private func checkScreenRecordingPermission(completion: @escaping (Bool) -> Void) {
        // 检查屏幕录制权限
        let hasPermission = CGPreflightScreenCaptureAccess()
        completion(hasPermission)
    }
    
    private func checkScreenRecordingPermissionSync() -> Bool {
        // 检查屏幕录制权限
        let screenCapturePermission = CGPreflightScreenCaptureAccess()
        return screenCapturePermission
    }
    
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
    
    @objc func startScreenshotCapture() {
        // 隐藏悬浮图标
        hideIcon()
        
        // 使用统一的截图服务
        ScreenshotService.shared.startScreenshotCapture(source: .floatingQuickIcon)
        
        // 延迟恢复图标显示（给截图操作一些时间）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showIcon()
        }
    }
    
    private func processScreenshotFromClipboard() {
        let clipboard = NSPasteboard.general
        guard let image = NSImage(pasteboard: clipboard) else {
            print("无法从剪贴板获取图片")
            showIcon()
            return
        }
        
        // 将NSImage转换为CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("无法将NSImage转换为CGImage")
            showIcon()
            return
        }
        
        // 执行OCR
        performOCR(on: cgImage)
    }
    
    private func performOCR(on image: NSImage) {
        print("FloatingQuickIcon: 开始OCR处理")
        
        // 将NSImage转换为CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("FloatingQuickIcon: 无法将NSImage转换为CGImage")
            showIcon()
            return
        }
        
        print("FloatingQuickIcon: 成功转换为CGImage，开始Vision识别")
        performOCR(on: cgImage)
    }
    
    private func performOCR(on image: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("OCR识别失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showIcon()
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("无法获取OCR结果")
                DispatchQueue.main.async {
                    self?.showIcon()
                }
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async { [weak self] in
                if !recognizedText.isEmpty {
                    self?.showFloatingResultWindow(text: recognizedText)
                } else {
                    print(LocalizationManager.localized("no_text_detected"))
                    self?.showIcon()
                }
            }
        }
        
        // 设置识别语言
        request.recognitionLanguages = getOCRLanguages()
        request.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("执行OCR请求失败: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.showIcon()
            }
        }
    }
    
    private func getOCRLanguages() -> [String] {
        // 从UserDefaults获取语言设置
        let sourceLanguageCode = UserDefaults.standard.string(forKey: "AITransSourceLanguageCode")
        
        if let languageCode = sourceLanguageCode, languageCode != "auto" {
            return [languageCode]
        } else {
            // 自动检测模式，返回常用语言
            return ["en", "zh-Hans", "zh-Hant", "ja", "ko", "th", "vi", "es", "fr", "de"]
        }
    }
    
    private func showFloatingResultWindow(text: String) {
        // 显示浮动结果窗口
        FloatingResultWindowManager.shared.showResultWindow(text: text)
        
        // 显示悬浮图标
        showIcon()
    }
    
    // MARK: - 显示/隐藏控制
    func showIcon() {
        guard !isVisible else { return }
        
        floatingWindow?.orderFront(nil)
        isVisible = true
        print("悬浮快捷图标已显示")
    }
    
    func hideIcon() {
        guard isVisible else { return }
        
        floatingWindow?.orderOut(nil)
        isVisible = false
        print("悬浮快捷图标已隐藏")
    }
    
    func toggleIcon() {
        if isVisible {
            hideIcon()
        } else {
            showIcon()
        }
    }
    
    // MARK: - 位置控制
    func moveToPosition(_ point: NSPoint) {
        floatingWindow?.setFrameOrigin(point)
    }
    
    func moveToBottomRight() {
        positionAtBottomRight()
    }
    
    func moveToBottomLeft() {
        guard let window = floatingWindow else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        
        let x: CGFloat = 20
        let y = screenFrame.minY + 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func moveToTopRight() {
        guard let window = floatingWindow else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowSize = window.frame.size
        
        let x = screenFrame.maxX - windowSize.width - 20
        let y = screenFrame.maxY - windowSize.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func moveToTopLeft() {
        guard let window = floatingWindow else { return }
        
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let windowSize = window.frame.size
        
        let x: CGFloat = 20
        let y = screenFrame.maxY - windowSize.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    deinit {
        print("FloatingQuickIcon 正在被释放")
        floatingWindow?.close()
        floatingWindow = nil
    }
}

// MARK: - 悬浮快捷图标管理器
class FloatingQuickIconManager {
    static let shared: FloatingQuickIconManager = FloatingQuickIconManager()
    
    private var floatingIcon: FloatingQuickIcon?
    
    private init() {}
    
    func showIcon() {
        if floatingIcon == nil {
            floatingIcon = FloatingQuickIcon()
        }
        floatingIcon?.showIcon()
    }
    
    func hideIcon() {
        floatingIcon?.hideIcon()
    }
    
    func toggleIcon() {
        if floatingIcon == nil {
            floatingIcon = FloatingQuickIcon()
        }
        floatingIcon?.toggleIcon()
    }
    
    func moveToPosition(_ point: NSPoint) {
        floatingIcon?.moveToPosition(point)
    }
    
    func moveToCorner(_ corner: IconCorner) {
        guard let icon = floatingIcon else { return }
        
        switch corner {
        case .bottomRight:
            icon.moveToBottomRight()
        case .bottomLeft:
            icon.moveToBottomLeft()
        case .topRight:
            icon.moveToTopRight()
        case .topLeft:
            icon.moveToTopLeft()
        }
    }
}

enum IconCorner {
    case bottomRight
    case bottomLeft
    case topRight
    case topLeft
}
