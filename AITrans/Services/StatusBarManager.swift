import SwiftUI
import AppKit
import Vision
import CoreGraphics

class StatusBarManager: ObservableObject {
    private var statusBarItem: NSStatusItem?
    
    // OCR识别结果
    @Published var recognizedText: String = ""
    
    // 当前选择的语言
    private var currentSourceLanguage: String = ""
    private var currentSourceLanguageCode: String? = nil
    private var currentTargetLanguage: String = ""
    private var currentTargetLanguageCode: String? = nil
    
    // 本地化管理器
    private let localizationManager = LocalizationManager.shared
    
    // UserDefaults 键名
    private let sourceLanguageKey = "AITransSourceLanguage"
    private let sourceLanguageCodeKey = "AITransSourceLanguageCode"
    private let targetLanguageKey = "AITransTargetLanguage"
    private let targetLanguageCodeKey = "AITransTargetLanguageCode"
    
    // CGEventTap 相关属性
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var middleMouseDownTime: CFTimeInterval = 0
    private let longPressThreshold: CFTimeInterval = 0.3 // 0.3秒长按阈值
    private var longPressTimer: Timer?
    
    init() {
        loadLanguageSettings()
        setupLocalizationObserver()
        DispatchQueue.main.async {
            self.setupStatusBar()
            self.setupGlobalEventTap()
            // 启动时检查权限
            self.checkPermissionsOnStartup()
        }
    }
    
    /// 设置本地化观察者
    private func setupLocalizationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: NSNotification.Name("LanguageChanged"),
            object: nil
        )
    }
    
    /// 语言切换处理
    @objc private func languageChanged() {
        DispatchQueue.main.async {
            self.createMenu()
        }
    }
    
    deinit {
        print("StatusBarManager 正在被释放")
        stopGlobalEventTap()
        
        // 清理定时器
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        // 清理状态栏
        statusBarItem = nil
    }
    
    
    // MARK: - Status Bar Setup
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "AITrans")
            button.image?.isTemplate = true
            button.action = #selector(buttonClicked)
            button.target = self
        }
        
        // 创建菜单并直接设置给状态栏项
        createMenu()
    }
    
    private func createMenu() {
        let menu = NSMenu()
        
        // 设置简单专业的菜单样式
        menu.autoenablesItems = false
        
        // 初始化快捷键管理器
        _ = KeyboardShortcutManager.shared
        
        // 创建权限检查菜单项
        let permissionCheckItem = NSMenuItem(
            title: localizationManager.permissionCheck,
            action: #selector(showPermissionCheck),
            keyEquivalent: ""
        )
        permissionCheckItem.target = self
        permissionCheckItem.image = NSImage(systemSymbolName: "checkmark.shield", accessibilityDescription: localizationManager.permissionCheck)
        permissionCheckItem.image?.isTemplate = true
        permissionCheckItem.isEnabled = true
        
        menu.addItem(permissionCheckItem)
        menu.addItem(NSMenuItem.separator())
        
        // 创建截图菜单项 - 简单专业风格
        let screenshotItem = NSMenuItem(
            title: "\(localizationManager.screenshotOCR) (⇧⌘S)",
            action: #selector(startScreenshotCapture),
            keyEquivalent: ""
        )
        screenshotItem.target = self
        screenshotItem.image = NSImage(systemSymbolName: "camera", accessibilityDescription: localizationManager.screenshotOCR)
        screenshotItem.image?.isTemplate = true
        screenshotItem.isEnabled = true
        
        menu.addItem(screenshotItem)
        menu.addItem(NSMenuItem.separator())
        
        // 创建翻译语言子菜单
        let sourceLanguageItem = NSMenuItem(
            title: localizationManager.translationLanguage,
            action: nil,
            keyEquivalent: ""
        )
        
        // 创建翻译语言子菜单
        let sourceLanguageSubmenu = NSMenu()
        sourceLanguageSubmenu.autoenablesItems = false
        
        // 自动检测选项
        let autoDetectItem = NSMenuItem(
            title: localizationManager.autoDetect,
            action: #selector(selectSourceLanguage(_:)),
            keyEquivalent: ""
        )
        autoDetectItem.target = self
        autoDetectItem.tag = 0 // 0 表示自动检测
        autoDetectItem.isEnabled = true
        // 检查是否为自动检测：currentSourceLanguageCode 为 nil
        if currentSourceLanguageCode == nil {
            autoDetectItem.state = .on
        }
        sourceLanguageSubmenu.addItem(autoDetectItem)
        
        sourceLanguageSubmenu.addItem(NSMenuItem.separator())
        
        // 主要支持的语言列表
        let supportedLanguages = [
            (localizationManager.english, "en"),
            (localizationManager.chineseSimplified, "zh-CN"),
            (localizationManager.chineseTraditional, "zh-TW"),
            (localizationManager.spanish, "es"),
            (localizationManager.french, "fr"),
            (localizationManager.german, "de"),
            (localizationManager.japanese, "ja"),
            (localizationManager.korean, "ko"),
            (localizationManager.thai, "th"),
            (localizationManager.vietnamese, "vi")
        ]
        
        for (languageName, languageCode) in supportedLanguages {
            let languageItem = NSMenuItem(
                title: languageName,
                action: #selector(selectSourceLanguage(_:)),
                keyEquivalent: ""
            )
            languageItem.target = self
            languageItem.tag = languageCode.hashValue // 使用语言代码的哈希值作为tag
            languageItem.representedObject = languageCode // 存储语言代码
            languageItem.isEnabled = true
            // 使用语言代码进行比较，而不是显示名称
            if currentSourceLanguageCode == languageCode {
                languageItem.state = .on
            }
            sourceLanguageSubmenu.addItem(languageItem)
        }
        
        sourceLanguageItem.submenu = sourceLanguageSubmenu
        menu.addItem(sourceLanguageItem)
        
        // 创建目标语言子菜单
        let targetLanguageItem = NSMenuItem(
            title: localizationManager.targetLanguage,
            action: nil,
            keyEquivalent: ""
        )
        
        // 创建目标语言子菜单
        let targetLanguageSubmenu = NSMenu()
        targetLanguageSubmenu.autoenablesItems = false
        
        // 系统语言选项
        let systemLanguageItem = NSMenuItem(
            title: localizationManager.systemLanguage,
            action: #selector(selectTargetLanguage(_:)),
            keyEquivalent: ""
        )
        systemLanguageItem.target = self
        systemLanguageItem.tag = 0 // 0 表示系统语言
        systemLanguageItem.isEnabled = true
        // 检查是否为系统语言：currentTargetLanguageCode 等于系统语言代码
        if currentTargetLanguageCode == getSystemLanguageCode() {
            systemLanguageItem.state = .on
        }
        targetLanguageSubmenu.addItem(systemLanguageItem)
        
        targetLanguageSubmenu.addItem(NSMenuItem.separator())
        
        // 主要支持的目标语言列表
        let targetLanguages = [
            (localizationManager.english, "en"),
            (localizationManager.chineseSimplified, "zh-CN"),
            (localizationManager.chineseTraditional, "zh-TW"),
            (localizationManager.spanish, "es"),
            (localizationManager.french, "fr"),
            (localizationManager.german, "de"),
            (localizationManager.japanese, "ja"),
            (localizationManager.korean, "ko"),
            (localizationManager.thai, "th"),
            (localizationManager.vietnamese, "vi")
        ]
        
        for (languageName, languageCode) in targetLanguages {
            let languageItem = NSMenuItem(
                title: languageName,
                action: #selector(selectTargetLanguage(_:)),
                keyEquivalent: ""
            )
            languageItem.target = self
            languageItem.tag = languageCode.hashValue // 使用语言代码的哈希值作为tag
            languageItem.representedObject = languageCode // 存储语言代码
            languageItem.isEnabled = true
            // 使用语言代码进行比较，而不是显示名称
            if currentTargetLanguageCode == languageCode {
                languageItem.state = .on
            }
            targetLanguageSubmenu.addItem(languageItem)
        }
        
        targetLanguageItem.submenu = targetLanguageSubmenu
        menu.addItem(targetLanguageItem)
        menu.addItem(NSMenuItem.separator())
        
        // 创建语言切换菜单
        let languageItem = NSMenuItem(
            title: localizationManager.interfaceLanguage,
            action: nil,
            keyEquivalent: ""
        )
        languageItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Language")
        languageItem.image?.isTemplate = true
        
        // 创建语言切换子菜单
        let languageSubmenu = NSMenu()
        languageSubmenu.autoenablesItems = false
        
        // 支持的语言列表
        let interfaceLanguages: [(LocalizationManager.Language, Int)] = [
            (.english, 0),
            (.chinese, 1),
            (.traditionalChinese, 2),
            (.spanish, 3),
            (.french, 4),
            (.german, 5),
            (.japanese, 6),
            (.korean, 7),
            (.thai, 8),
            (.vietnamese, 9)
        ]
        
        // 为每种语言创建菜单项
        for (language, tag) in interfaceLanguages {
            let languageItem = NSMenuItem(
                title: language.nativeName,
                action: #selector(selectAppLanguage(_:)),
                keyEquivalent: ""
            )
            languageItem.target = self
            languageItem.tag = tag
            languageItem.isEnabled = true
            if localizationManager.currentLanguage == language {
                languageItem.state = .on
            }
            languageSubmenu.addItem(languageItem)
        }
        
        languageItem.submenu = languageSubmenu
        menu.addItem(languageItem)
        menu.addItem(NSMenuItem.separator())
        
        // 创建悬浮快捷图标控制菜单项
        let floatingIconItem = NSMenuItem(
            title: localizationManager.floatingIcon,
            action: nil,
            keyEquivalent: ""
        )
        floatingIconItem.image = NSImage(systemSymbolName: "circle.grid.2x2", accessibilityDescription: "Floating Icon")
        floatingIconItem.image?.isTemplate = true
        
        // 创建悬浮快捷图标子菜单
        let floatingIconSubmenu = NSMenu()
        floatingIconSubmenu.autoenablesItems = false
        
        // 显示/隐藏悬浮图标
        let showHideIconItem = NSMenuItem(
            title: localizationManager.showFloatingIcon,
            action: #selector(toggleFloatingIcon),
            keyEquivalent: "f"
        )
        showHideIconItem.target = self
        showHideIconItem.isEnabled = true
        floatingIconSubmenu.addItem(showHideIconItem)
        
        floatingIconSubmenu.addItem(NSMenuItem.separator())
        
        // 位置选项
        let positionItem = NSMenuItem(
            title: localizationManager.position,
            action: nil,
            keyEquivalent: ""
        )
        positionItem.image = NSImage(systemSymbolName: "location", accessibilityDescription: localizationManager.position)
        positionItem.image?.isTemplate = true
        
        // 创建位置子菜单
        let positionSubmenu = NSMenu()
        positionSubmenu.autoenablesItems = false
        
        let bottomRightItem = NSMenuItem(
            title: localizationManager.bottomRight,
            action: #selector(moveIconToBottomRight),
            keyEquivalent: ""
        )
        bottomRightItem.target = self
        bottomRightItem.isEnabled = true
        positionSubmenu.addItem(bottomRightItem)
        
        let bottomLeftItem = NSMenuItem(
            title: localizationManager.bottomLeft,
            action: #selector(moveIconToBottomLeft),
            keyEquivalent: ""
        )
        bottomLeftItem.target = self
        bottomLeftItem.isEnabled = true
        positionSubmenu.addItem(bottomLeftItem)
        
        let topRightItem = NSMenuItem(
            title: localizationManager.topRight,
            action: #selector(moveIconToTopRight),
            keyEquivalent: ""
        )
        topRightItem.target = self
        topRightItem.isEnabled = true
        positionSubmenu.addItem(topRightItem)
        
        let topLeftItem = NSMenuItem(
            title: localizationManager.topLeft,
            action: #selector(moveIconToTopLeft),
            keyEquivalent: ""
        )
        topLeftItem.target = self
        topLeftItem.isEnabled = true
        positionSubmenu.addItem(topLeftItem)
        
        positionItem.submenu = positionSubmenu
        floatingIconSubmenu.addItem(positionItem)
        
        floatingIconItem.submenu = floatingIconSubmenu
        menu.addItem(floatingIconItem)
        menu.addItem(NSMenuItem.separator())
        
        // 创建退出菜单项 - 简单专业风格
        let quitItem = NSMenuItem(
            title: localizationManager.quitApp,
            action: #selector(quitApplication),
            keyEquivalent: "q"
        )
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: localizationManager.quitApp)
        quitItem.image?.isTemplate = true
        quitItem.isEnabled = true
        
        menu.addItem(quitItem)
        
        // 直接设置菜单给状态栏项，让系统自动处理位置
        statusBarItem?.menu = menu
    }
    
    
    // MARK: - Button Actions
    
    @objc private func buttonClicked() {
        // 由于菜单已经直接设置给状态栏项，系统会自动处理点击事件
        // 这里不需要手动显示菜单
        print("Status bar button clicked - menu will be shown automatically")
    }
    
    @objc private func selectSourceLanguage(_ sender: NSMenuItem) {
        if sender.tag == 0 {
            // 自动检测
            currentSourceLanguage = localizationManager.autoDetect
            currentSourceLanguageCode = nil
            print("选择翻译语言: \(localizationManager.autoDetect)")
        } else if let languageCode = sender.representedObject as? String {
            // 具体语言
            currentSourceLanguage = sender.title
            currentSourceLanguageCode = languageCode
            print("选择翻译语言: \(sender.title) (\(languageCode))")
        }
        
        // 保存设置
        saveLanguageSettings()
        
        // 更新菜单标题
        updateSourceLanguageMenuTitle()
    }
    
    private func updateSourceLanguageMenuTitle() {
        // 重新创建菜单以更新标题
        createMenu()
    }
    
    @objc private func selectTargetLanguage(_ sender: NSMenuItem) {
        if sender.tag == 0 {
            // 系统语言
            currentTargetLanguage = localizationManager.systemLanguage
            currentTargetLanguageCode = getSystemLanguageCode()
            print("选择目标语言: \(localizationManager.systemLanguage)")
        } else if let languageCode = sender.representedObject as? String {
            // 具体语言
            currentTargetLanguage = sender.title
            currentTargetLanguageCode = languageCode
            print("选择目标语言: \(sender.title) (\(languageCode))")
        }
        
        // 保存设置
        saveLanguageSettings()
        
        // 更新菜单标题
        updateTargetLanguageMenuTitle()
    }
    
    private func updateTargetLanguageMenuTitle() {
        // 重新创建菜单以更新标题
        createMenu()
    }
    
    // MARK: - 语言设置持久化
    
    private func loadLanguageSettings() {
        // 加载源语言设置
        if let savedSourceLanguage = UserDefaults.standard.string(forKey: sourceLanguageKey) {
            currentSourceLanguage = savedSourceLanguage
        } else {
            // 默认设置为自动检测
            currentSourceLanguage = localizationManager.autoDetect
        }
        
        if let savedSourceLanguageCode = UserDefaults.standard.string(forKey: sourceLanguageCodeKey) {
            currentSourceLanguageCode = savedSourceLanguageCode
        } else {
            // 自动检测不需要语言代码
            currentSourceLanguageCode = nil
        }
        
        // 加载目标语言设置
        if let savedTargetLanguage = UserDefaults.standard.string(forKey: targetLanguageKey) {
            currentTargetLanguage = savedTargetLanguage
        } else {
            // 默认设置为系统语言
            currentTargetLanguage = localizationManager.systemLanguage
        }
        
        if let savedTargetLanguageCode = UserDefaults.standard.string(forKey: targetLanguageCodeKey) {
            currentTargetLanguageCode = savedTargetLanguageCode
        } else {
            // 系统语言需要根据当前系统语言设置代码
            currentTargetLanguageCode = getSystemLanguageCode()
        }
        
        print("已加载语言设置 - 源语言: \(currentSourceLanguage), 目标语言: \(currentTargetLanguage)")
    }
    
    private func saveLanguageSettings() {
        // 保存源语言设置
        UserDefaults.standard.set(currentSourceLanguage, forKey: sourceLanguageKey)
        if let sourceLanguageCode = currentSourceLanguageCode {
            UserDefaults.standard.set(sourceLanguageCode, forKey: sourceLanguageCodeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: sourceLanguageCodeKey)
        }
        
        // 保存目标语言设置
        UserDefaults.standard.set(currentTargetLanguage, forKey: targetLanguageKey)
        if let targetLanguageCode = currentTargetLanguageCode {
            UserDefaults.standard.set(targetLanguageCode, forKey: targetLanguageCodeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: targetLanguageCodeKey)
        }
        
        print("已保存语言设置 - 源语言: \(currentSourceLanguage), 目标语言: \(currentTargetLanguage)")
    }
    
    /// 获取系统语言代码
    /// - Returns: 系统语言代码
    private func getSystemLanguageCode() -> String {
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "zh"
        return mapToTranslationCode(systemLanguage)
    }
    
    /// 将系统语言代码映射为翻译API语言代码
    /// - Parameter systemCode: 系统语言代码
    /// - Returns: 翻译API语言代码
    private func mapToTranslationCode(_ systemCode: String) -> String {
        let mapping: [String: String] = [
            "en": "en",
            "zh": "zh-CN",  // 默认简体中文
            "es": "es",
            "fr": "fr",
            "de": "de",
            "ja": "ja",
            "ko": "ko",
            "th": "th",
            "vi": "vi"
        ]
        return mapping[systemCode] ?? "zh-CN"
    }
    
    /// 将翻译API语言代码映射为OCR识别语言代码
    /// - Parameter translationCode: 翻译API语言代码
    /// - Returns: OCR识别语言代码
    private func mapToOCRLanguageCode(_ translationCode: String) -> String {
        let mapping: [String: String] = [
            "en": "en-US",
            "zh-CN": "zh-Hans",
            "zh-TW": "zh-Hant",
            "es": "es-ES",
            "fr": "fr-FR",
            "de": "de-DE",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "th": "th-TH",
            "vi": "vi-VN"
        ]
        return mapping[translationCode] ?? "en-US"
    }
    
    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - 语言切换处理
    
    @objc private func selectAppLanguage(_ sender: NSMenuItem) {
        let newLanguage: LocalizationManager.Language
        switch sender.tag {
        case 0:
            newLanguage = .english
        case 1:
            newLanguage = .chinese
        case 2:
            newLanguage = .traditionalChinese
        case 3:
            newLanguage = .spanish
        case 4:
            newLanguage = .french
        case 5:
            newLanguage = .german
        case 6:
            newLanguage = .japanese
        case 7:
            newLanguage = .korean
        case 8:
            newLanguage = .thai
        case 9:
            newLanguage = .vietnamese
        default:
            return
        }
        
        // 切换语言
        localizationManager.setLanguage(newLanguage)
        
        // 更新当前语言显示名称
        updateLanguageDisplayNames()
        
        print("Language switched to: \(newLanguage.displayName)")
    }
    
    /// 更新语言显示名称
    private func updateLanguageDisplayNames() {
        // 更新源语言显示名称
        if currentSourceLanguage == "自动检测" || currentSourceLanguage == "Auto Detect" {
            currentSourceLanguage = localizationManager.autoDetect
        }
        
        // 更新目标语言显示名称
        if currentTargetLanguage == "系统语言" || currentTargetLanguage == "System Language" {
            currentTargetLanguage = localizationManager.systemLanguage
        }
    }
    
    // MARK: - Permission Check Functions
    
    @objc private func showPermissionCheck() {
        // 创建权限检查窗口
        let permissionWindow = PermissionCheckWindow()
        permissionWindow.showWindow()
    }
    
    // MARK: - Screenshot and OCR Functions
    
    @objc func startScreenshotCapture() {
        // 使用统一的截图服务
        ScreenshotService.shared.startScreenshotCapture(source: .statusBar)
    }
    
    private func checkScreenRecordingPermission() -> Bool {
        // 检查屏幕录制权限
        let screenCapturePermission = CGPreflightScreenCaptureAccess()
        return screenCapturePermission
    }
    
    private func performOCR(on image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("OCR识别错误: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("OCR识别结果为空")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            // 原始多行文本
            let multiLineText = recognizedStrings.joined(separator: "\n")
            print("OCR识别结果(多行): \(multiLineText)")
            
            // 将多行文本转换为一行，用空格连接
            let singleLineText = self?.convertToSingleLine(multiLineText) ?? multiLineText
            print("OCR识别结果(一行): \(singleLineText)")
            
            DispatchQueue.main.async {
                self?.recognizedText = singleLineText
                
                // 检查是否识别出文本
                if singleLineText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // 没有识别出文本，显示提醒
                    self?.showFloatingResultWindow(text: LocalizationManager.localized("no_text_detected"))
                } else {
                    // 将识别的文字复制到剪贴板
                    self?.copyTextToClipboard(singleLineText)
                    
                    // 显示弹出窗口
                    self?.showFloatingResultWindow(text: singleLineText)
                }
            }
        }
        
        // 设置识别参数
        request.recognitionLevel = .accurate  // 高精度识别
        request.usesLanguageCorrection = true // 启用语言纠正
        
        // 根据用户选择的源语言设置OCR识别语言
        if let sourceLanguageCode = currentSourceLanguageCode {
            // 用户指定了具体语言，使用该语言进行识别
            request.automaticallyDetectsLanguage = false
            let ocrLanguageCode = mapToOCRLanguageCode(sourceLanguageCode)
            request.recognitionLanguages = [ocrLanguageCode]
            print("OCR使用指定语言识别: \(currentSourceLanguage) (\(sourceLanguageCode) -> \(ocrLanguageCode))")
        } else {
            // 用户选择自动检测，使用多语言识别
            request.automaticallyDetectsLanguage = true
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant", "es-ES", "fr-FR", "de-DE", "pt-BR", "it-IT", "th-TH", "vi-VN"]
            print("OCR使用自动检测语言识别")
        }
        
        // 执行识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: - Clipboard Operations
    
    private func copyTextToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("📋 已将识别文字复制到剪贴板: \(text)")
    }
    
    // MARK: - Floating Result Window
    
    private func showFloatingResultWindow(text: String) {
        print("显示浮动窗口，文本内容: \(text)")
        // 获取当前鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        print("StatusBarManager: 当前鼠标位置: \(mouseLocation)")
        
        // 确保在主线程执行UI操作
        DispatchQueue.main.async {
            FloatingResultWindowManager.shared.showResultWindow(text: text)
        }
    }
    
    // MARK: - Global Event Tap
    
    private func setupGlobalEventTap() {
        // 检查辅助功能权限
        guard checkAccessibilityPermission() else {
            print("需要辅助功能权限才能捕获全局鼠标事件")
            return
        }
        
        // 创建事件类型掩码
        let eventMask = (1 << CGEventType.otherMouseDown.rawValue) | (1 << CGEventType.otherMouseUp.rawValue)
        
        // 创建事件回调
        let eventCallback: CGEventTapCallBack = { (proxy, type, event, refcon) in
            guard let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }
            
            let statusBarManager = Unmanaged<StatusBarManager>.fromOpaque(refcon).takeUnretainedValue()
            return statusBarManager.handleGlobalEvent(proxy: proxy, type: type, event: event)
        }
        
        // 创建事件tap
        eventTap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else {
            print("创建事件tap失败")
            return
        }
        
        // 创建运行循环源
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        guard let runLoopSource = runLoopSource else {
            print("创建运行循环源失败")
            return
        }
        
        // 添加到运行循环
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // 启用事件tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("全局事件捕获已启动")
    }
    
    private func stopGlobalEventTap() {
        // 取消定时器
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        print("全局事件捕获已停止")
    }
    
    private func handleGlobalEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .otherMouseDown:
            // 检查是否是中键按下
            if event.getIntegerValueField(.mouseEventButtonNumber) == 2 {
                middleMouseDownTime = CACurrentMediaTime()
                print("中键按下，开始计时")
                
                // 取消之前的定时器
                longPressTimer?.invalidate()
                
                // 创建新的定时器，1秒后触发截图
                longPressTimer = Timer.scheduledTimer(withTimeInterval: longPressThreshold, repeats: false) { [weak self] _ in
                    print("检测到中键长按1秒，开始截图")
                    DispatchQueue.main.async {
                        self?.startScreenshotCapture()
                    }
                }
            }
            
        case .otherMouseUp:
            // 检查是否是中键松开
            if event.getIntegerValueField(.mouseEventButtonNumber) == 2 {
                print("中键松开，取消定时器")
                // 取消定时器
                longPressTimer?.invalidate()
                longPressTimer = nil
            }
            
        default:
            break
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - 测试翻译功能
    @objc private func testTranslation() {
        print("StatusBarManager: 测试翻译功能被调用")
        
        // 使用测试文本显示窗口
        let testText = "This is a test for translation functionality"
        FloatingResultWindowManager.shared.showResultWindow(text: testText)
        
        // 测试翻译服务
        Task {
            do {
                let translation = try await TranslationService.shared.translate(text: testText)
                print("StatusBarManager: 翻译结果: \(translation)")
            } catch {
                print("StatusBarManager: 翻译失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Text Processing
    
    /// 将多行文本转换为单行文本
    /// - Parameter text: 多行文本
    /// - Returns: 单行文本
    private func convertToSingleLine(_ text: String) -> String {
        // 按行分割文本
        let lines = text.components(separatedBy: .newlines)
        
        // 过滤空行并去除每行首尾空格
        let cleanedLines = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 用空格连接所有行，形成一行文本
        let singleLineText = cleanedLines.joined(separator: " ")
        
        print("StatusBarManager: 多行转单行 - 原文本行数: \(lines.count), 清理后行数: \(cleanedLines.count)")
        print("StatusBarManager: 转换前: \(text.replacingOccurrences(of: "\n", with: "\\n"))")
        print("StatusBarManager: 转换后: \(singleLineText)")
        
        return singleLineText
    }
    
    // MARK: - 悬浮快捷图标控制
    
    @objc private func toggleFloatingIcon() {
        FloatingQuickIconManager.shared.toggleIcon()
        print("切换悬浮快捷图标显示状态")
    }
    
    @objc private func moveIconToBottomRight() {
        FloatingQuickIconManager.shared.moveToCorner(.bottomRight)
        print("移动悬浮图标到右下角")
    }
    
    @objc private func moveIconToBottomLeft() {
        FloatingQuickIconManager.shared.moveToCorner(.bottomLeft)
        print("移动悬浮图标到左下角")
    }
    
    @objc private func moveIconToTopRight() {
        FloatingQuickIconManager.shared.moveToCorner(.topRight)
        print("移动悬浮图标到右上角")
    }
    
    @objc private func moveIconToTopLeft() {
        FloatingQuickIconManager.shared.moveToCorner(.topLeft)
        print("移动悬浮图标到左上角")
    }
    
    // MARK: - 启动时权限检查
    
    /// 启动时检查权限
    private func checkPermissionsOnStartup() {
        print("StatusBarManager: 开始启动时权限检查")
        
        // 检查屏幕录制权限
        let screenRecordingPermission = CGPreflightScreenCaptureAccess()
        print("StatusBarManager: 屏幕录制权限状态: \(screenRecordingPermission)")
        
        // 检查辅助功能权限
        let accessibilityPermission = checkAccessibilityPermission()
        print("StatusBarManager: 辅助功能权限状态: \(accessibilityPermission)")
        
        // 如果任一权限未授权，显示权限检查窗口
        if !screenRecordingPermission || !accessibilityPermission {
            print("StatusBarManager: 检测到权限未授权，显示权限检查窗口")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showPermissionCheckWindow()
            }
        } else {
            print("StatusBarManager: 所有权限已授权，应用正常运行")
        }
    }
    
    /// 显示权限检查窗口
    private func showPermissionCheckWindow() {
        let permissionWindow = PermissionCheckWindow()
        permissionWindow.showWindow()
    }
}