//
//  FloatingResultWindow.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import AppKit
import Vision
import CoreGraphics

// MARK: - 翻译显示视图
class TokenizedTextView: NSView {
    private var tokens: [TokenItem] = []
    var tokenButtons: [TokenButton] = []
    private var screenshotButton: ScreenshotButton!
    private var pinButton: NSButton!
    private var containerView: NSView!
    private var lineViews: [NSView] = []
    var sourceText: String = ""
    weak var translationView: TranslationView?
    weak var parentWindow: FloatingResultWindow? {
        didSet {
            // 当parentWindow被设置后，更新ScreenshotButton的parentWindow
            screenshotButton?.parentWindow = parentWindow
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        
        // 设置浅蓝色背景
        layer?.backgroundColor = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).cgColor
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        
        // 添加边框与翻译面板保持一致
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.systemGray.cgColor
        
        // 添加增强阴影
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow?.shadowOffset = NSSize(width: 0, height: -4)
        shadow?.shadowBlurRadius = 16
        
        setupSubviews()
        setupConstraints()
    }
    
    private func setupSubviews() {
        
        // 创建截图按钮
        screenshotButton = ScreenshotButton()
        screenshotButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(screenshotButton)
        
        // 设置parentWindow（如果已经存在）
        if parentWindow != nil {
            screenshotButton.parentWindow = parentWindow
        }
        
        // 创建固定/关闭按钮
        pinButton = NSButton()
        setupPinButton()
        addSubview(pinButton)
        
        // 创建容器视图用于多行布局
        containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 截图按钮约束 - 位于左上角
            screenshotButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            
            // 固定/关闭按钮约束 - 位于最右边
            pinButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            pinButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            pinButton.heightAnchor.constraint(equalToConstant: 24),
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            
            // 容器视图约束 - 位于截图按钮和固定按钮之间
            containerView.leadingAnchor.constraint(equalTo: screenshotButton.trailingAnchor, constant: 4),
            containerView.trailingAnchor.constraint(equalTo: pinButton.leadingAnchor, constant: -4),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        
        // 初始设置图标按钮的垂直居中位置（默认16pt字体）
        updateIconButtonAlignment(for: "en")
    }
    
    // MARK: - 固定按钮设置
    private func setupPinButton() {
        // 使用固定相关的SF Symbols图标
        if let image = NSImage(systemSymbolName: "pin", accessibilityDescription: "固定") {
            pinButton.image = image
            pinButton.imagePosition = .imageOnly
        } else if let image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "固定") {
            pinButton.image = image
            pinButton.imagePosition = .imageOnly
        } else {
            // 如果SF Symbols不可用，使用文本
            pinButton.title = "📌"
            pinButton.font = NSFont.systemFont(ofSize: 16, weight: .medium)
            pinButton.imagePosition = .noImage
        }
        
        pinButton.isBordered = false
        pinButton.wantsLayer = true
        pinButton.layer?.backgroundColor = NSColor.clear.cgColor
        pinButton.contentTintColor = .systemOrange
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        pinButton.target = self
        pinButton.action = #selector(pinButtonClicked)
        pinButton.isHidden = false
        
        // 设置固定按钮样式
        pinButton.imageHugsTitle = true
        pinButton.bezelStyle = .texturedSquare
        pinButton.setButtonType(.momentaryPushIn)
        pinButton.focusRingType = .none
        
        // 创建自定义的按钮样式，去除内边距
        let pinCell = pinButton.cell as? NSButtonCell
        pinCell?.imageDimsWhenDisabled = false
        pinCell?.imageScaling = .scaleNone
        
        // 设置按钮内容边距为0
        pinButton.wantsLayer = true
        if let layer = pinButton.layer {
            layer.masksToBounds = false
        }
    }
    
    @objc private func pinButtonClicked() {
        guard let parentWindow = parentWindow else { return }
        
        // 只支持固定状态，点击关闭图标隐藏窗口
        parentWindow.hide()
    }
    
    /// 更新分词面板固定按钮的显示状态
    func updatePinButtonState() {
        // 只支持固定状态，始终显示关闭图标
        if let image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "关闭窗口") {
            pinButton.image = image
            pinButton.imagePosition = .imageOnly
        }
        pinButton.contentTintColor = .systemRed
    }
    
    /// 根据语言更新图标按钮的垂直对齐
    /// - Parameter language: 语言代码
    private func updateIconButtonAlignment(for language: String) {
        // 计算第一行文字的中心位置
        let fontSize: CGFloat = 18
        let textHeight = fontSize + 8 // 字体高度 + 内边距
        let firstLineCenter = 8 + textHeight / 2 // containerView顶部 + 第一行文字中心
        
        // 设置新的垂直约束
        screenshotButton.centerYConstraint = screenshotButton.centerYAnchor.constraint(equalTo: topAnchor, constant: firstLineCenter)
        
        // 激活新约束
        screenshotButton.centerYConstraint?.isActive = true
    }
    
    func updateText(_ text: String) {
        // 保存源文本
        sourceText = text
        
        // 检查是否是提示文本
        let isWarningText = text.contains(LocalizationManager.localized("no_text_detected"))
        
        // 检查源语言是否需要分词
        let (sourceLanguage, _) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
        
        if sourceLanguage == "auto" {
            // 自动检测模式：先进行分词来检测语言
            let optimizedText = optimizeTextForTokenization(text)
            let newTokens = TokenizationService.shared.tokenize(optimizedText)
            
            if newTokens.isEmpty {
                return
            }
            
            // 获取检测到的语言
            let detectedLanguage = newTokens.first?.language ?? "en"
            
            // 根据检测到的语言决定是否需要分词
            let shouldTokenize = shouldPerformTokenization(for: detectedLanguage)
            
            if shouldTokenize {
                // 检测到的语言需要分词：使用分词结果
                clearTokens()
                tokens = newTokens
                
                if let firstToken = newTokens.first {
                    updateIconButtonAlignment(for: firstToken.language)
                }
                
                createTokenButtons()
                
                if isWarningText {
                    setTextTransparency(alpha: 0.0)
                } else {
                    setTextTransparency(alpha: 1.0)
                }
                
                layoutTokensInLines()
            } else {
                // 检测到的语言不需要分词：显示原始文本
                clearTokens()
                
                let fullTextToken = TokenItem(
                    text: text,
                    range: NSRange(location: 0, length: text.utf16.count),
                    tokenType: .word,
                    isWord: false,
                    language: detectedLanguage,
                    partOfSpeech: nil
                )
                
                tokens = [fullTextToken]
                updateIconButtonAlignment(for: detectedLanguage)
                createTokenButtons()
                
                if isWarningText {
                    setTextTransparency(alpha: 0.0)
                } else {
                    setTextTransparency(alpha: 1.0)
                }
                
                layoutTokensInLines()
            }
        } else {
            // 指定语言模式：直接根据设置判断
            let shouldTokenize = shouldPerformTokenization(for: sourceLanguage)
            
            if shouldTokenize {
                // 需要分词的语言：进行正常的分词处理
                let optimizedText = optimizeTextForTokenization(text)
                let newTokens = TokenizationService.shared.tokenize(optimizedText)
                
                if newTokens.isEmpty {
                    return
                }
                
                clearTokens()
                tokens = newTokens
                
                if let firstToken = newTokens.first {
                    updateIconButtonAlignment(for: firstToken.language)
                }
                
                createTokenButtons()
                
                if isWarningText {
                    setTextTransparency(alpha: 0.0)
                } else {
                    setTextTransparency(alpha: 1.0)
                }
                
                layoutTokensInLines()
            } else {
                // 不需要分词的语言：直接显示原始文本
                clearTokens()
                
                let fullTextToken = TokenItem(
                    text: text,
                    range: NSRange(location: 0, length: text.utf16.count),
                    tokenType: .word,
                    isWord: false,
                    language: sourceLanguage,
                    partOfSpeech: nil
                )
                
                tokens = [fullTextToken]
                updateIconButtonAlignment(for: sourceLanguage)
                createTokenButtons()
                
                if isWarningText {
                    setTextTransparency(alpha: 0.0)
                } else {
                    setTextTransparency(alpha: 1.0)
                }
                
                layoutTokensInLines()
            }
        }
        
        // 按钮状态在初始化时已设置，无需重复更新
        
        needsLayout = true
        needsDisplay = true
    }
    
    func getSourceText() -> String {
        return sourceText
    }
    
    /// 设置文本透明度
    private func setTextTransparency(alpha: CGFloat) {
        for button in tokenButtons {
            button.alphaValue = alpha
        }
    }
    
    /// 取消所有单词的选中状态
    func deselectAllWords() {
        var hasSelectedWords = false
        for button in tokenButtons {
            if button.isWordSelected() {
                button.deselectWord()
                hasSelectedWords = true
            }
        }
        
        // 如果有单词被取消选择，恢复源文本翻译
        if hasSelectedWords {
            restoreSourceTranslation()
        }
    }
    
    /// 恢复源文本翻译
    func restoreSourceTranslation() {
        guard let translationView = translationView else { return }
        
        // 获取源文本
        let sourceText = self.sourceText
        guard !sourceText.isEmpty else { return }
        
        
        // 开始翻译
        translationView.startTranslating()
        
        // 异步翻译文本
        Task {
            do {
                // 获取用户设置的语言参数
                let (sourceLanguage, targetLanguage) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
                let translation = try await TranslationService.shared.translate(
                    text: sourceText,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                await MainActor.run {
                    parentWindow?.handleTranslationResult(translation)
                }
            } catch {
                await MainActor.run {
                    parentWindow?.handleTranslationResult("\(LocalizationManager.localized("translation_failed")): \(error.localizedDescription)", isError: true)
                }
            }
        }
    }
    
    /// 取消指定单词外的所有其他单词的选中状态
    func deselectAllWordsExcept(_ exceptButton: TokenButton) {
        for button in tokenButtons {
            if button !== exceptButton && button.isWordSelected() {
                // 直接取消选中状态，不调用restoreSourceTranslation
                button.deselectWordWithoutRestore()
            }
        }
    }
    
    /// 获取当前选中的单词
    /// - Returns: 选中的单词文本，如果没有选中则返回nil
    func getSelectedWord() -> String? {
        for button in tokenButtons {
            if button.isWordSelected() {
                return button.token.text
            }
        }
        return nil
    }
    
    /// 判断指定语言是否需要分词处理
    /// - Parameter language: 语言代码
    /// - Returns: 是否需要分词
    private func shouldPerformTokenization(for language: String) -> Bool {
        // 不需要分词的语言列表
        let noTokenizationLanguages = ["ja", "ko", "fr", "de", "es", "vi"]
        
        // 如果是自动检测，需要根据实际检测到的语言来判断
        if language == "auto" {
            // 对于自动检测，我们需要根据文本内容来判断语言
            // 这里我们暂时返回true，让分词服务来处理语言检测
            // 分词服务会返回实际检测到的语言，然后我们可以在updateText中再次判断
            return true
        }
        
        // 检查是否在不需要分词的语言列表中
        return !noTokenizationLanguages.contains(language)
    }
    
    /// 优化文本用于分词处理
    /// - Parameter text: 原始文本
    /// - Returns: 优化后的文本
    private func optimizeTextForTokenization(_ text: String) -> String {
        var optimizedText = text
        
        // 移除多余的空格和换行符
        optimizedText = optimizedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // 移除首尾空格
        optimizedText = optimizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除特殊控制字符（保留标点符号用于分词）
        optimizedText = optimizedText.replacingOccurrences(of: "[\\r\\n\\t\\f\\v]+", with: " ", options: .regularExpression)
        
        // 只移除真正的不可见字符，保留正常标点符号
        // 移除零宽字符和格式控制字符，但保留标点符号
        optimizedText = optimizedText.replacingOccurrences(of: "[\\u2000-\\u200F\\u2028-\\u202F\\u205F-\\u206F\\uFEFF]+", with: " ", options: .regularExpression)
        
        // 再次清理多余空格
        optimizedText = optimizedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        optimizedText = optimizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        return optimizedText
    }
    
    private func clearTokens() {
        // 清除所有按钮
        tokenButtons.forEach { $0.removeFromSuperview() }
        tokenButtons.removeAll()
        
        // 清除所有行视图
        lineViews.forEach { $0.removeFromSuperview() }
        lineViews.removeAll()
    }
    
    private func createTokenButtons() {
        for token in tokens {
            let tokenButton = TokenButton(token: token, translationView: translationView, parentWindow: parentWindow)
            tokenButton.translatesAutoresizingMaskIntoConstraints = false
            tokenButtons.append(tokenButton)
        }
        
        // 检查除去特殊字符和标点符号后是否只有一个单词
        let wordTokens = tokens.filter { token in
            // 过滤掉标点符号和特殊字符，只保留真正的单词
            let cleanText = token.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !cleanText.isEmpty && 
                   token.isWord && 
                   !isPunctuationOrSpecialCharacter(cleanText)
        }
        
        // 如果只有一个单词，自动选中它
        if wordTokens.count == 1, let wordToken = wordTokens.first {
            DispatchQueue.main.async { [weak self] in
                // 找到对应的按钮并选中
                if let targetButton = self?.tokenButtons.first(where: { button in
                    button.token.text == wordToken.text && button.token.range == wordToken.range
                }) {
                    targetButton.selectWord()
                    print("🎯 自动选中单词: \(wordToken.text)")
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func isPunctuationOrSpecialCharacter(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否为空
        if trimmedText.isEmpty {
            return true
        }
        
        // 检查是否只包含标点符号和特殊字符
        let punctuationAndSpecialChars = CharacterSet.punctuationCharacters
            .union(.symbols)
            .union(.whitespacesAndNewlines)
            .union(CharacterSet(charactersIn: ".,!?;:'\"()[]{}<>/\\|@#$%^&*+=~`"))
        
        // 如果所有字符都是标点符号或特殊字符，则认为是标点符号
        return trimmedText.unicodeScalars.allSatisfy { punctuationAndSpecialChars.contains($0) }
    }
    
    private func layoutTokensInLines() {
        guard !tokenButtons.isEmpty else { return }
        
        let maxWidth: CGFloat = 1024
        let horizontalPadding: CGFloat = 16 // 左右边距
        let screenshotButtonWidth = screenshotButton.fittingSize.width
        let buttonSpacing: CGFloat = 4 // 按钮和分词按钮之间的间距
        let verticalSpacing: CGFloat = 4 // 行间距
        let availableWidth = maxWidth - horizontalPadding - screenshotButtonWidth - buttonSpacing
        
        var currentLine: [TokenButton] = []
        var currentLineWidth: CGFloat = 0
        var allLines: [[TokenButton]] = []
        
        // 将按钮分配到不同的行
        for button in tokenButtons {
            let buttonWidth = button.fittingSize.width
            
            // 如果当前行加上这个按钮会超出宽度，则开始新行
            if currentLineWidth + buttonWidth > availableWidth && !currentLine.isEmpty {
                allLines.append(currentLine)
                currentLine = [button]
                currentLineWidth = buttonWidth
            } else {
                currentLine.append(button)
                currentLineWidth += buttonWidth
            }
        }
        
        // 添加最后一行
        if !currentLine.isEmpty {
            allLines.append(currentLine)
        }
        
        // 创建行视图并添加按钮
        for (lineIndex, lineButtons) in allLines.enumerated() {
            let lineView = NSView()
            lineView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(lineView)
            lineViews.append(lineView)
            
            // 创建水平堆栈视图用于这一行
            let lineStackView = NSStackView()
            lineStackView.translatesAutoresizingMaskIntoConstraints = false
            lineStackView.orientation = .horizontal
            lineStackView.alignment = .firstBaseline
            lineStackView.distribution = .gravityAreas
            lineStackView.spacing = 0
            lineView.addSubview(lineStackView)
            
            // 智能对齐：单行时居中，多行时左对齐
            let isMultiLine = allLines.count > 1
            if isMultiLine {
                // 多行时：左对齐
                lineStackView.alignment = .firstBaseline
            } else {
                // 单行时：居中对齐
                lineStackView.alignment = .centerY
            }
            
            // 添加按钮到这一行
            for button in lineButtons {
                lineStackView.addArrangedSubview(button)
            }
            
            // 设置行视图约束 - 智能对齐
            if isMultiLine {
                // 多行时：左对齐
                NSLayoutConstraint.activate([
                    lineStackView.leadingAnchor.constraint(equalTo: lineView.leadingAnchor),
                    lineStackView.trailingAnchor.constraint(lessThanOrEqualTo: lineView.trailingAnchor),
                    lineStackView.topAnchor.constraint(equalTo: lineView.topAnchor),
                    lineStackView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor),
                    
                    lineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    lineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    lineView.heightAnchor.constraint(equalToConstant: lineButtons.map { $0.fittingSize.height }.max() ?? 20)
                ])
            } else {
                // 单行时：居中对齐
                NSLayoutConstraint.activate([
                    lineStackView.centerXAnchor.constraint(equalTo: lineView.centerXAnchor),
                    lineStackView.topAnchor.constraint(equalTo: lineView.topAnchor),
                    lineStackView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor),
                    
                    lineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                    lineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                    lineView.heightAnchor.constraint(equalToConstant: lineButtons.map { $0.fittingSize.height }.max() ?? 20)
                ])
            }
            
            // 设置行之间的垂直约束
            if lineIndex == 0 {
                lineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            } else {
                lineView.topAnchor.constraint(equalTo: lineViews[lineIndex - 1].bottomAnchor, constant: verticalSpacing).isActive = true
            }
            
            if lineIndex == allLines.count - 1 {
                lineView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
            }
        }
        
    }
    
    func fittingSize() -> NSSize {
        // 分词面板宽度限制在320-1024之间（不同于翻译面板的0-1024）
        let maxWidth: CGFloat = 1024
        let minWidth: CGFloat = 320
        let horizontalPadding: CGFloat = 16 // 左右边距
        let verticalPadding: CGFloat = 16 // 上下边距
        let verticalSpacing: CGFloat = 4 // 行间距
        
        // 计算按钮的宽度
        let screenshotButtonWidth = screenshotButton.fittingSize.width
        let pinButtonWidth: CGFloat = 24 // 固定按钮宽度
        let buttonSpacing: CGFloat = 4 // 按钮和分词按钮之间的间距
        
        guard !tokenButtons.isEmpty else {
            let totalWidth = screenshotButtonWidth + pinButtonWidth + buttonSpacing * 2 + minWidth
            return NSSize(width: totalWidth, height: 20 + verticalPadding)
        }
        
        // 计算多行布局的尺寸
        let availableWidth = maxWidth - horizontalPadding - screenshotButtonWidth - pinButtonWidth - buttonSpacing * 2
        var currentLineWidth: CGFloat = 0
        var lineCount = 1
        var maxLineWidth: CGFloat = 0
        
        // 模拟多行布局计算
        for button in tokenButtons {
            let buttonWidth = button.fittingSize.width
            
            if currentLineWidth + buttonWidth > availableWidth && currentLineWidth > 0 {
                // 需要换行
                maxLineWidth = max(maxLineWidth, currentLineWidth)
                currentLineWidth = buttonWidth
                lineCount += 1
            } else {
                currentLineWidth += buttonWidth
            }
        }
        
        // 更新最大行宽度
        maxLineWidth = max(maxLineWidth, currentLineWidth)
        
        // 计算最终宽度和高度（包含两个按钮）
        let contentWidth = max(minWidth, min(maxLineWidth, availableWidth))
        let totalWidth = screenshotButtonWidth + pinButtonWidth + buttonSpacing * 2 + contentWidth + horizontalPadding
        let buttonHeight = tokenButtons.map { $0.fittingSize.height }.max() ?? 20
        let totalHeight = CGFloat(lineCount) * buttonHeight + CGFloat(max(0, lineCount - 1)) * verticalSpacing + verticalPadding
        
        
        return NSSize(width: totalWidth, height: totalHeight)
    }
}

// MARK: - 声音播放按钮
class AudioPlayButton: NSButton {
    private var sourceText: String = ""
    var centerYConstraint: NSLayoutConstraint?
    weak var tokenizedView: TokenizedTextView?
    var isMuted: Bool = false
    private var longPressTimer: Timer?
    private var isLongPress: Bool = false
    
    init() {
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // 设置按钮属性
        title = ""  // 清空文字，使用SF Symbols图标
        isBordered = false
        wantsLayer = true
        
        // 设置SF Symbols图标
        updateButtonIcon()
        contentTintColor = NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)  // 浅棕色
        
        // 设置按钮样式
        bezelStyle = .rounded
        isEnabled = true
        
        // 设置点击事件
        self.target = self
        self.action = #selector(playAudio)
        
        // 设置悬停效果
        setupHoverEffect()
    }
    
    private func setupHoverEffect() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 4
        
        // 添加鼠标跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的跟踪区域
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        // 添加新的跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - 鼠标事件处理
    // 声音播放按钮不需要拖动功能，移除拖动相关代码以支持正常点击
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.contentTintColor = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)  // 悬停时变为深棕色
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.contentTintColor = NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)  // 恢复浅棕色
    }
    
    override func mouseDown(with event: NSEvent) {
        // 开始长按检测
        isLongPress = false
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.isLongPress = true
            self?.toggleMute()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // 取消长按定时器
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        // 如果不是长按，则执行正常点击
        if !isLongPress {
            if isMuted {
                // 静音状态下点击：取消静音并播放
                toggleMute()
                playAudio()
            } else {
                // 正常状态下点击：播放音频
                playAudio()
            }
        }
    }
    
    @objc private func playAudio() {
        // 如果处于静音状态，不播放音频
        if isMuted {
            return
        }
        
        // 优先播放选中的单词
        if let selectedWord = tokenizedView?.getSelectedWord() {
            AudioService.shared.playText(selectedWord)
        } else {
            AudioService.shared.playText(sourceText)
        }
    }
    
    /// 更新按钮图标
    private func updateButtonIcon() {
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let iconName = isMuted ? "speaker.slash" : "speaker.wave.2"
            let speakerImage = NSImage(systemSymbolName: iconName, accessibilityDescription: isMuted ? "取消静音" : "播放音频")
            image = speakerImage?.withSymbolConfiguration(config)
        } else {
            // 降级方案：使用文字图标
            title = isMuted ? "🔇" : "🔊"
            let fontSize: CGFloat = 18
            if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
                font = sfProFont
            } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
                font = sfProTextFont
            } else {
                font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
            }
        }
    }
    
    /// 切换静音状态
    private func toggleMute() {
        isMuted.toggle()
        updateButtonIcon()
    }
    
    
    func setSourceText(_ text: String) {
        self.sourceText = text
    }
    
    func fittingSize() -> NSSize {
        let fontSize: CGFloat = 18
        
        let font: NSFont
        if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
            font = sfProFont
        } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
            font = sfProTextFont
        } else {
            font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
        
        let textSize = title.size(withAttributes: [.font: font])
        
        // 添加上下内边距4
        return NSSize(width: textSize.width, height: textSize.height + 8)
    }
}

// MARK: - 截图按钮
class ScreenshotButton: NSButton {
    var centerYConstraint: NSLayoutConstraint?
    weak var parentWindow: FloatingResultWindow?
    
    init() {
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // 设置按钮属性
        title = ""  // 清空文字，使用SF Symbols图标
        isBordered = false
        wantsLayer = true
        
        // 设置SF Symbols图标
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let cameraImage = NSImage(systemSymbolName: "camera", accessibilityDescription: "截图")
            image = cameraImage?.withSymbolConfiguration(config)
        } else {
            // 降级方案：使用文字图标
            title = "📷"
            let fontSize: CGFloat = 18
            if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
                font = sfProFont
            } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
                font = sfProTextFont
            } else {
                font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
            }
        }
        contentTintColor = NSColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0)  // 浅蓝色
        
        // 设置按钮样式
        bezelStyle = .rounded
        isEnabled = true
        
        // 设置点击事件
        self.target = self
        self.action = #selector(takeScreenshot)
        
        // 设置悬停效果
        setupHoverEffect()
    }
    
    private func setupHoverEffect() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 4
        
        // 添加鼠标跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的跟踪区域
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        // 添加新的跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - 鼠标事件处理
    // 截图按钮不需要拖动功能，移除拖动相关代码以支持正常点击
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.contentTintColor = .systemBlue
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.contentTintColor = NSColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0)  // 恢复浅蓝色
    }
    
    override func mouseDown(with event: NSEvent) {
        // 点击时不改变颜色，直接调用action
        if let action = self.action, let target = self.target {
            _ = target.perform(action, with: self)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // 点击时不改变颜色，保持当前颜色
    }
    
    @objc private func takeScreenshot() {
        
        // 通过父窗口调用StatusBarManager的截图功能
        if let parentWindow = parentWindow {
            parentWindow.startScreenshotCapture()
        }
    }
    
    
    func fittingSize() -> NSSize {
        let fontSize: CGFloat = 18
        
        let font: NSFont
        if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
            font = sfProFont
        } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
            font = sfProTextFont
        } else {
            font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
        
        let textSize = title.size(withAttributes: [.font: font])
        
        // 添加上下内边距4
        return NSSize(width: textSize.width, height: textSize.height + 8)
    }
}

// MARK: - 单个分词按钮
class TokenButton: NSButton {
    let token: TokenItem
    weak var translationView: TranslationView?
    weak var parentWindow: FloatingResultWindow?
    private var isSelected: Bool = false
    
    init(token: TokenItem, translationView: TranslationView? = nil, parentWindow: FloatingResultWindow? = nil) {
        self.token = token
        self.translationView = translationView
        self.parentWindow = parentWindow
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        // 设置按钮属性
        isBordered = false
        wantsLayer = true
        
        // 设置统一的字体大小
        let fontSize: CGFloat = 20
        // 使用现代专业的SF Pro字体
        var buttonFont: NSFont
        if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
            buttonFont = sfProFont
        } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
            buttonFont = sfProTextFont
        } else {
            // 备用字体：使用系统字体但调整权重
            buttonFont = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
        
        // 设置文字颜色
        let textColor = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)  // 深棕色
        
        // 创建属性字符串
        let displayText: String
        if isChineseText(token.text) {
            displayText = addSpacesBetweenChineseCharacters(token.text)
        } else {
            displayText = token.text
        }
        
        let attributedString = NSMutableAttributedString(string: displayText)
        
        // 设置字体和颜色
        attributedString.addAttribute(.font, value: buttonFont, range: NSRange(location: 0, length: displayText.utf16.count))
        attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: displayText.utf16.count))
        
        // 如果是中文文本，添加下划线
        if isChineseText(token.text) {
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: displayText.utf16.count))
            attributedString.addAttribute(.underlineColor, value: NSColor.lightGray, range: NSRange(location: 0, length: displayText.utf16.count))
        }
        
        // 设置按钮的标题为属性字符串
        attributedTitle = attributedString
        
        // 设置按钮样式
        bezelStyle = .rounded
        isEnabled = true
        
        // 设置悬停效果
        setupHoverEffect()
    }
    
    private func setupHoverEffect() {
        // 使用按钮的内置悬停效果
        self.target = self
        self.action = #selector(buttonClicked)
        
        // 设置按钮的悬停样式
        self.wantsLayer = true
        self.layer?.cornerRadius = 4
        
        // 添加鼠标跟踪区域（包括拖动功能）
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的跟踪区域
        for trackingArea in trackingAreas {
            removeTrackingArea(trackingArea)
        }
        
        // 添加新的跟踪区域（包括拖动功能）
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - 鼠标事件处理
    
    private var isDragging = false
    private var dragStartLocation: NSPoint = .zero
    
    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        isDragging = false
    }
    
    override func mouseUp(with event: NSEvent) {
        // 如果没有拖动，则执行点击事件
        if !isDragging {
            buttonClicked()
        }
        isDragging = false
    }
    
    override func mouseDragged(with event: NSEvent) {
        // 检查是否开始拖动
        let currentLocation = event.locationInWindow
        let deltaX = abs(currentLocation.x - dragStartLocation.x)
        let deltaY = abs(currentLocation.y - dragStartLocation.y)
        
        // 如果移动距离超过阈值，则开始拖动
        if deltaX > 3 || deltaY > 3 {
            isDragging = true
            if let window = self.window {
                window.performDrag(with: event)
            }
        }
    }
    
    // 重写 acceptsFirstMouse 以支持点击时立即开始拖动
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        // 只有单词才高亮，更新属性字符串
        if token.isWord {
            updateButtonAppearance(isSelected: isSelected, isHovered: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        // 只有单词才恢复原始样式
        if token.isWord {
            updateButtonAppearance(isSelected: isSelected, isHovered: false)
        }
    }
    
    // MARK: - 右键点击功能
    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        
        // 检查按钮是否完全透明（不可用状态）
        if alphaValue <= 0.0 {
            return
        }
        
        // 右键点击播放OCR源文本（无论是否分词）
        if let tokenizedView = findTokenizedView() {
            AudioService.shared.playText(tokenizedView.sourceText)
            print("🔊 右键播放OCR源文本: \(tokenizedView.sourceText)")
        }
    }
    
    
    @objc private func buttonClicked() {
        // 检查按钮是否完全透明（不可用状态）
        if alphaValue <= 0.0 {
            return
        }
        
        // 添加点击动画反馈
        animateClick()
        
        if token.isWord {
            // 分词情况：处理单词选中状态
            if isSelected {
                // 如果当前单词已选中，只朗读发音，不取消选中（使用原始句子作为上下文）
                if let tokenizedView = findTokenizedView() {
                    AudioService.shared.playText(token.text, context: tokenizedView.sourceText)
                    print("🔊 播放已选中单词发音: \(token.text) (上下文: \(tokenizedView.sourceText))")
                } else {
                    AudioService.shared.playText(token.text)
                    print("🔊 播放已选中单词发音: \(token.text)")
                }
            } else {
                // 先取消其他单词的选中状态
                deselectOtherWords()
                
                // 选中当前单词并播放发音
                selectWord()
            }
        } else {
            // 没有分词的情况：左键点击朗读OCR源文本
            if let tokenizedView = findTokenizedView() {
                AudioService.shared.playText(tokenizedView.sourceText)
                print("🔊 左键播放OCR源文本: \(tokenizedView.sourceText)")
            }
        }
    }
    
    private func animateClick() {
        // 已移除点击缩放动画效果
        // 保持按钮原始大小，不进行缩放
    }
    
    /// 选中当前单词（公开方法）
    func selectWord() {
        // 检查按钮是否完全透明（不可用状态）
        if alphaValue <= 0.0 {
            return
        }
        
        isSelected = true
        setSelectedState()
        
        // 隐藏AI详细解释面板（当切换词语时）
        if let parentWindow = parentWindow {
            parentWindow.hideAIDetailExplanationPanel()
        }
        
        // 播放选中文本的语言（使用原始句子作为上下文，提高语言检测准确性）
        if let tokenizedView = findTokenizedView() {
            AudioService.shared.playText(token.text, context: tokenizedView.sourceText)
            print("🔊 左键播放选中文本: \(token.text) (上下文: \(tokenizedView.sourceText))")
        } else {
            AudioService.shared.playText(token.text)
            print("🔊 左键播放选中文本: \(token.text)")
        }
        
        // 翻译词汇并在翻译面板显示
        translateAndDisplayWord(token.text)
    }
    
    /// 选中当前单词（不播放音频）
    func selectWordWithoutAudio() {
        // 检查按钮是否完全透明（不可用状态）
        if alphaValue <= 0.0 {
            return
        }
        
        isSelected = true
        setSelectedState()
        
        // 隐藏AI详细解释面板（当切换词语时）
        if let parentWindow = parentWindow {
            parentWindow.hideAIDetailExplanationPanel()
        }
        
        // 翻译词汇并在翻译面板显示（不播放音频）
        translateAndDisplayWord(token.text)
    }
    
    /// 取消选中当前单词（内部方法）
    private func deselectWordInternal() {
        isSelected = false
        setDefaultState()
        
        // 恢复源文本翻译
        restoreSourceTranslation()
    }
    
    /// 取消其他单词的选中状态
    private func deselectOtherWords() {
        // 通过父视图找到TokenizedTextView并取消其他单词的选中状态
        if let tokenizedView = findTokenizedView() {
            tokenizedView.deselectAllWordsExcept(self)
        }
    }
    
    /// 查找TokenizedTextView
    private func findTokenizedView() -> TokenizedTextView? {
        var currentView: NSView? = self.superview
        while currentView != nil {
            if let tokenizedView = currentView as? TokenizedTextView {
                return tokenizedView
            }
            currentView = currentView?.superview
        }
        return nil
    }
    
    /// 检查当前单词是否被选中
    func isWordSelected() -> Bool {
        return isSelected
    }
    
    /// 外部调用的取消选中方法
    func deselectWord() {
        if isSelected {
            isSelected = false
            setDefaultState()
            
            // 只有在手动点击取消选中时才恢复源文本翻译
            // 如果是被其他单词选中时取消，则不恢复源文本翻译
            restoreSourceTranslation()
        }
    }
    
    /// 取消选中但不恢复源文本翻译（用于被其他单词选中时取消）
    func deselectWordWithoutRestore() {
        if isSelected {
            isSelected = false
            setDefaultState()
        }
    }
    
    private func setSelectedState() {
        // 设置加粗紫色样式，使用属性字符串支持下划线
        updateButtonAppearance(isSelected: true, isHovered: false)
    }
    
    private func setDefaultState() {
        // 恢复默认样式，使用属性字符串支持下划线
        updateButtonAppearance(isSelected: false, isHovered: false)
    }
    
    /// 更新按钮外观（支持选中和悬停状态）
    private func updateButtonAppearance(isSelected: Bool, isHovered: Bool) {
        let displayText: String
        if isChineseText(token.text) {
            displayText = addSpacesBetweenChineseCharacters(token.text)
        } else {
            displayText = token.text
        }
        
        let fontSize: CGFloat = 20
        var buttonFont: NSFont
        if isSelected {
            // 选中状态使用粗体
            if let sfProFont = NSFont(name: "SF Pro Display Bold", size: fontSize) {
                buttonFont = sfProFont
            } else if let sfProTextFont = NSFont(name: "SF Pro Text Bold", size: fontSize) {
                buttonFont = sfProTextFont
            } else {
                buttonFont = NSFont.systemFont(ofSize: fontSize, weight: .bold)
            }
        } else {
            // 未选中状态使用半粗体
            if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
                buttonFont = sfProFont
            } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
                buttonFont = sfProTextFont
            } else {
                buttonFont = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
            }
        }
        
        // 确定文字颜色
        let textColor: NSColor
        if isSelected {
            textColor = .systemPurple
        } else {
            textColor = NSColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        }
        
        let attributedString = NSMutableAttributedString(string: displayText)
        
        // 设置字体和颜色
        attributedString.addAttribute(.font, value: buttonFont, range: NSRange(location: 0, length: displayText.utf16.count))
        attributedString.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: displayText.utf16.count))
        
        // 如果是中文文本，添加下划线
        if isChineseText(token.text) {
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: displayText.utf16.count))
            attributedString.addAttribute(.underlineColor, value: NSColor.lightGray, range: NSRange(location: 0, length: displayText.utf16.count))
        }
        
        // 更新按钮的标题
        attributedTitle = attributedString
    }
    
    private func restoreSourceTranslation() {
        // 恢复源文本翻译，通过父窗口调用TokenizedTextView的方法
        if let parentWindow = parentWindow,
           let tokenizedView = parentWindow.tokenizedContentView {
            tokenizedView.restoreSourceTranslation()
        }
    }
    
    private func translateAndDisplayWord(_ word: String) {
        guard let translationView = translationView else {
            return
        }
        
        // 显示翻译中状态
        translationView.startTranslating()
        
        // 异步翻译词汇
        Task {
            do {
                // 获取用户设置的语言参数
                let (sourceLanguage, targetLanguage) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
                let translation = try await TranslationService.shared.translate(
                    text: word,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                
                // 在主线程更新UI，包含词性信息
                await MainActor.run {
                    let displayText = formatTranslationWithPartOfSpeech(word: word, translation: translation, partOfSpeech: token.partOfSpeech)
                    translationView.showWordTranslation(displayText)
                    translationView.stopTranslating()
                }
            } catch {
                
                // 在主线程显示错误信息
                await MainActor.run {
                    translationView.showWordTranslation(LocalizationManager.localized("translation_failed"))
                    translationView.stopTranslating()
                }
            }
        }
    }
    
    /// 格式化翻译结果，包含词性信息、音标和拼音
    /// - Parameters:
    ///   - word: 单词
    ///   - translation: 翻译结果
    ///   - partOfSpeech: 词性
    /// - Returns: 格式化后的显示文本
    private func formatTranslationWithPartOfSpeech(word: String, translation: String, partOfSpeech: String?) -> String {
        // 检查源语言
        let (sourceLanguage, _) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
        let isEnglish = sourceLanguage == "en" || sourceLanguage == "auto"
        let isChinese = sourceLanguage == "zh" || (sourceLanguage == "auto" && PinyinService.shared.containsChinese(word))
        
        var result = ""
        
        // 添加词性信息
        if let pos = partOfSpeech, !pos.isEmpty, pos != "unknown", pos != "other" {
            result += "\(pos) "
        }
        
        // 添加单词
        result += word
        
        // 如果是英语，添加音标
        if isEnglish {
            if let phoneticInfo = PhoneticService.shared.getDetailedPhoneticInfo(for: word) {
                result += " \(phoneticInfo.ipa)"
            }
        }
        
        // 如果是中文，添加拼音
        if isChinese {
            if let pinyin = PinyinService.shared.getPinyin(for: word) {
                result += " [\(pinyin)]"
            }
        }
        
        // 添加翻译
        result += " → \(translation)"
        
        return result
    }
    
    func fittingSize() -> NSSize {
        // 设置统一的字体大小
        let fontSize: CGFloat = 20
        
        // 使用与setupButton相同的字体逻辑
        let font: NSFont
        if let sfProFont = NSFont(name: "SF Pro Display", size: fontSize) {
            font = sfProFont
        } else if let sfProTextFont = NSFont(name: "SF Pro Text", size: fontSize) {
            font = sfProTextFont
        } else {
            font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
        
        // 使用与显示相同的文本（中文带空格）
        let displayText = isChineseText(token.text) ? addSpacesBetweenChineseCharacters(token.text) : token.text
        let textSize = displayText.size(withAttributes: [.font: font])
        
        // 添加上下内边距4
        return NSSize(width: textSize.width, height: textSize.height + 8)
    }
    
    /// 判断文本是否为中文
    private func isChineseText(_ text: String) -> Bool {
        // 检查文本中是否包含中文字符
        let chineseRegex = "[\u{4e00}-\u{9fff}]"
        return text.range(of: chineseRegex, options: .regularExpression) != nil
    }
    
    /// 在中文文本的每个汉字之间添加半角空格
    private func addSpacesBetweenChineseCharacters(_ text: String) -> String {
        var result = ""
        var lastChar: Character?
        
        for char in text {
            if let last = lastChar {
                // 如果前一个字符是汉字，当前字符也是汉字，则在它们之间添加空格
                if isChineseCharacter(last) && isChineseCharacter(char) {
                    result += " "
                }
            }
            result += String(char)
            lastChar = char
        }
        
        return result
    }
    
    /// 判断单个字符是否为汉字
    private func isChineseCharacter(_ char: Character) -> Bool {
        let unicode = char.unicodeScalars.first?.value ?? 0
        // 中文字符的Unicode范围：4E00-9FFF
        return unicode >= 0x4E00 && unicode <= 0x9FFF
    }
}

// MARK: - 浮动结果窗口
class FloatingResultWindow: NSWindow {
    var containerView: NSView!
    private var translationView: TranslationView!
    var tokenizedContentView: TokenizedTextView!
    var aiDetailExplanationPanel: AIDetailExplanationPanel!
    private var globalMouseMonitor: Any?
    
    // MARK: - 窗口固定状态管理
    
    init() {
        // 计算屏幕居中靠近顶部的位置
        let initialSize = NSSize(width: 300, height: 100)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // 计算居中位置，Y坐标设置为屏幕顶部向下100像素
        let centerX = screenFrame.midX - initialSize.width / 2
        let topY = screenFrame.maxY - initialSize.height - 100
        
        let windowRect = NSRect(
            x: centerX,
            y: topY,
            width: initialSize.width,
            height: initialSize.height
        )
        
        super.init(contentRect: windowRect,
                  styleMask: [.borderless],
                  backing: .buffered,
                  defer: false)
        
        setupWindow()
        setupGlobalMouseMonitor()
        
        // 确保窗口在初始化时是隐藏的
        orderOut(nil)
    }
    
    required init?(coder: NSCoder) {
        // NSWindow 不支持从 coder 初始化，使用默认初始化
        let initialSize = NSSize(width: 300, height: 100)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // 计算居中位置，Y坐标设置为屏幕顶部向下100像素
        let centerX = screenFrame.midX - initialSize.width / 2
        let topY = screenFrame.maxY - initialSize.height - 100
        
        let windowRect = NSRect(
            x: centerX,
            y: topY,
            width: initialSize.width,
            height: initialSize.height
        )
        
        super.init(contentRect: windowRect,
                  styleMask: [.borderless],
                  backing: .buffered,
                  defer: false)
        
        setupWindow()
        setupGlobalMouseMonitor()
        
        // 确保窗口在初始化时是隐藏的
        orderOut(nil)
    }
    
    private func setupWindow() {
        // 窗口基本设置
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = false  // 移除窗口默认阴影，让面板的阴影成为主导
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // 设置为可拖拽
        isMovableByWindowBackground = true
        isMovable = true
        
        // 移除窗口边框，让翻译面板的样式成为主导
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        contentView?.layer?.cornerRadius = 0
        contentView?.layer?.masksToBounds = false
        
        // 创建容器视图
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        
        // 创建翻译视图
        translationView = TranslationView(frame: NSRect(origin: .zero, size: NSSize(width: 300, height: 40)))
        translationView.translatesAutoresizingMaskIntoConstraints = false
        translationView.parentWindow = self
        
        // 创建分词视图
        tokenizedContentView = TokenizedTextView(frame: NSRect(origin: .zero, size: NSSize(width: 300, height: 100)))
        tokenizedContentView.translatesAutoresizingMaskIntoConstraints = false
        tokenizedContentView.parentWindow = self
        
        // 创建AI详细解释面板
        aiDetailExplanationPanel = AIDetailExplanationPanel()
        aiDetailExplanationPanel.translatesAutoresizingMaskIntoConstraints = false
        aiDetailExplanationPanel.parentWindow = self
        
        // 设置翻译面板引用
        tokenizedContentView.translationView = translationView
        
        // 添加子视图到容器
        containerView.addSubview(translationView)
        containerView.addSubview(tokenizedContentView)
        containerView.addSubview(aiDetailExplanationPanel)
        
        // 设置约束 - 允许每个面板独立调整宽度
        NSLayoutConstraint.activate([
            // 翻译视图约束 - 使用centerX约束而不是leading/trailing
            translationView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            translationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            // 翻译视图宽度将由其内容决定，通过fittingSize()和updatePanelConstraints()设置
            
            // 分词视图约束 - 同样使用centerX约束
            tokenizedContentView.topAnchor.constraint(equalTo: translationView.bottomAnchor, constant: 8),
            tokenizedContentView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            // 分词视图宽度将由其内容决定，通过fittingSize()和updatePanelConstraints()设置
            
            // AI详细解释面板约束 - 位于分词视图下方
            aiDetailExplanationPanel.topAnchor.constraint(equalTo: tokenizedContentView.bottomAnchor, constant: 8),
            aiDetailExplanationPanel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            aiDetailExplanationPanel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
            // AI详细解释面板宽度将由其内容决定，通过fittingSize()和updatePanelConstraints()设置
        ])
        
        // 设置容器为内容视图
        self.contentView = containerView
        
        // 设置窗口为固定状态
        setPinnedState()
        
    }
    
    deinit {
        // 清理全局鼠标监听器
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        translationView = nil
        tokenizedContentView = nil
        aiDetailExplanationPanel = nil
        containerView = nil
    }
    
    // MARK: - 窗口固定状态管理
    
    /// 设置窗口为固定状态（不再支持切换）
    func setPinnedState() {
        // 窗口始终为固定状态
        // 更新固定按钮状态
        updatePinButtonState()
    }
    
    /// 更新固定按钮的显示状态
    func updatePinButtonState() {
        // 更新分词面板的固定按钮状态
        tokenizedContentView?.updatePinButtonState()
    }
    
    
    /// 隐藏浮动翻译窗口
    func hide() {
        // 清空AI分析缓存，确保下次显示时使用最新提示词
        AIAnalysisService.shared.clearCache()
        print("🧹 浮动面板隐藏时已清空AI分析缓存")
        
        orderOut(nil)
    }
    
    
    func updateText(_ text: String) {
        // 完全在后台准备所有内容，不显示窗口
        prepareContentInBackground(text: text)
    }
    
    /// 在后台准备所有内容，完成后一次性显示
    private func prepareContentInBackground(text: String) {
        // 开始翻译
        translationView.startTranslating()
        
        // 异步翻译文本
        Task {
            do {
                // 获取用户设置的语言参数
                let (sourceLanguage, targetLanguage) = getLanguageSettings()
                let translation = try await TranslationService.shared.translate(
                    text: text,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                await MainActor.run {
                    // 完全在后台准备所有内容
                    self.prepareAllContent(text: text, translation: translation)
                }
            } catch {
                await MainActor.run {
                    // 完全在后台准备所有内容（包括错误信息）
                    self.prepareAllContent(text: text, translation: "\(LocalizationManager.localized("translation_failed")): \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 准备所有内容并一次性显示
    private func prepareAllContent(text: String, translation: String) {
        // 确保窗口在准备期间是隐藏的
        orderOut(nil)
        
        // 1. 更新分词视图内容（但不显示）
        tokenizedContentView?.updateText(text)
        
        // 2. 更新翻译内容（但不显示）
        translationView.updateTranslation(translation)
        translationView.stopTranslating()
        
        // 3. 计算并设置最终窗口大小
        updateWindowSize()
        
        // 4. 强制完成所有布局
        contentView?.needsLayout = true
        contentView?.layout()
        
        // 5. 等待一个运行循环，确保所有布局都完成
        DispatchQueue.main.async { [weak self] in
            // 6. 最后一次性显示窗口
            self?.showWindow()
        }
    }
    
    
    /// 显示窗口
    private func showWindow() {
        orderFront(nil)
        makeKeyAndOrderFront(nil)
    }
    
    /// 获取用户设置的语言参数
    /// - Returns: (源语言代码, 目标语言代码)
    func getLanguageSettings() -> (String, String) {
        // 从UserDefaults读取用户设置
        let sourceLanguage = UserDefaults.standard.string(forKey: "AITransSourceLanguageCode") ?? "auto"
        let targetLanguage = UserDefaults.standard.string(forKey: "AITransTargetLanguageCode")
        let targetLanguageName = UserDefaults.standard.string(forKey: "AITransTargetLanguage")
        
        // 处理系统语言的情况
        let finalTargetLanguage: String
        if targetLanguage?.isEmpty != false || targetLanguageName == LocalizationManager.localized("system_language") {
            // 获取系统语言
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "zh"
            finalTargetLanguage = mapToTranslationCode(systemLanguage)
        } else {
            finalTargetLanguage = targetLanguage ?? "zh"
        }
        
        return (sourceLanguage, finalTargetLanguage)
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
    
    /// 重新翻译全文，使用当前的语言设置
    func retranslateFullText() {
        guard let tokenizedView = tokenizedContentView else { return }
        
        // 获取源文本
        let sourceText = tokenizedView.sourceText
        guard !sourceText.isEmpty else { return }
        
        
        // 开始翻译
        translationView.startTranslating()
        
        // 异步翻译文本
        Task {
            do {
                // 获取用户设置的语言参数
                let (sourceLanguage, targetLanguage) = getLanguageSettings()
                let translation = try await TranslationService.shared.translate(
                    text: sourceText,
                    from: sourceLanguage,
                    to: targetLanguage
                )
                await MainActor.run {
                    self.handleTranslationResult(translation)
                }
            } catch {
                await MainActor.run {
                    self.handleTranslationResult("\(LocalizationManager.localized("translation_failed")): \(error.localizedDescription)", isError: true)
                }
            }
        }
    }
    
    func updateWindowSize() {
        // 调整窗口大小以适应内容
        guard let contentView = tokenizedContentView else { return }
        let contentSize = contentView.fittingSize()
        let translationSize = translationView.fittingSize()
        // AI面板尺寸：使用当前高度约束值
        let aiPanelHeight = aiPanelHeightConstraint?.constant ?? 80
        let aiPanelSize = NSSize(width: 300, height: aiPanelHeight)
        
        
        // 计算总尺寸：根据各个面板是否显示来调整间距
        let hasTranslation = translationSize.width > 0 && translationSize.height > 0
        let hasAIPanel = aiDetailExplanationPanel.isVisible
        let totalHeight: CGFloat
        
        if hasTranslation && hasAIPanel {
            // 有翻译内容和AI面板：翻译视图高度 + 分词视图高度 + AI面板高度 + 间距(8+8+8+8)
            totalHeight = translationSize.height + contentSize.height + aiPanelHeight + 32
        } else if hasTranslation {
            // 只有翻译内容：翻译视图高度 + 分词视图高度 + 间距(8+8+8)
            totalHeight = translationSize.height + contentSize.height + 24
        } else if hasAIPanel {
            // 只有AI面板：分词视图高度 + AI面板高度 + 间距(8+8+8)
            totalHeight = contentSize.height + aiPanelHeight + 24
        } else {
            // 无额外内容：只显示分词视图 + 上下边距(8+8)
            totalHeight = contentSize.height + 16
        }
        
        // 新逻辑：让每个面板保持自己的宽度，窗口宽度取较大者但允许内容独立调整
        let maxContentWidth = max(translationSize.width, contentSize.width, aiPanelSize.width)
        let totalWidth = maxContentWidth + 80 // 大幅增加左右边距，确保有足够空间显示所有字符
        
        let newSize = NSSize(
            width: max(0, totalWidth),
            height: totalHeight // 移除最小高度限制，完全根据内容自适应
        )
        
        // 使用新的窗口大小调整方法：相对于上一次位置居中，顶部对齐
        resizeWindowTopAlignedAndCenteredToPrevious(window: self, newContentSize: newSize)
        
        // 更新各个面板的约束，让它们能够独立调整宽度
        updatePanelConstraints(translationSize: translationSize, contentSize: contentSize, aiPanelSize: aiPanelSize)
    }
    
    /// 调整窗口大小：相对于上一次位置居中，顶部对齐
    private func resizeWindowTopAlignedAndCenteredToPrevious(window: NSWindow, newContentSize: NSSize) {
        let currentFrame = window.frame
        let contentRect = window.contentRect(forFrameRect: currentFrame)
        
        // 计算窗口大小变化
        let deltaHeight = newContentSize.height - contentRect.height
        let deltaWidth  = newContentSize.width - contentRect.width
        
        // 目标frame
        var newFrame = currentFrame
        newFrame.size.width  += deltaWidth
        newFrame.size.height += deltaHeight
        
        // 顶部对齐（保持 topY 不动）
        let topY = currentFrame.origin.y + currentFrame.height
        newFrame.origin.y = topY - newFrame.height
        
        // 相对居中（保持原来的中心 X 不变）
        let centerX = currentFrame.midX
        newFrame.origin.x = centerX - newFrame.width / 2
        
        // 应用
        window.setFrame(newFrame, display: true, animate: false)
    }
    
    // 存储宽度约束的引用，以便动态更新
    private var translationWidthConstraint: NSLayoutConstraint?
    private var tokenizedWidthConstraint: NSLayoutConstraint?
    private var aiPanelWidthConstraint: NSLayoutConstraint?
    private var aiPanelHeightConstraint: NSLayoutConstraint?
    
    private func updatePanelConstraints(translationSize: NSSize, contentSize: NSSize, aiPanelSize: NSSize) {
        // 移除现有的宽度约束
        translationWidthConstraint?.isActive = false
        tokenizedWidthConstraint?.isActive = false
        aiPanelWidthConstraint?.isActive = false
        
        // 判断各个面板是否应该显示
        let hasTranslation = translationSize.width > 0 && translationSize.height > 0
        let hasAIPanel = aiDetailExplanationPanel.isVisible
        
        
        // 设置翻译面板的可见性和约束
        translationView.isHidden = !hasTranslation
        
        if hasTranslation {
            // 有翻译内容时设置宽度约束
            translationWidthConstraint = translationView.widthAnchor.constraint(equalToConstant: translationSize.width)
            translationWidthConstraint?.isActive = true
        }
        
        // 设置分词面板约束
        if let tokenizedView = tokenizedContentView {
            tokenizedWidthConstraint = tokenizedView.widthAnchor.constraint(equalToConstant: contentSize.width)
            tokenizedWidthConstraint?.isActive = true
        }
        
        // 设置AI详细解释面板约束
        if hasAIPanel {
            aiPanelWidthConstraint = aiDetailExplanationPanel.widthAnchor.constraint(equalToConstant: 300)
            aiPanelWidthConstraint?.isActive = true
            
            // 设置AI面板高度约束（默认80，可通过setHeight动态调整）
            if aiPanelHeightConstraint == nil {
                aiPanelHeightConstraint = aiDetailExplanationPanel.heightAnchor.constraint(equalToConstant: 80)
                aiPanelHeightConstraint?.isActive = true
            }
        }
        
    }
    
    // MARK: - 公共方法
    
    /// 处理翻译结果的公共方法
    func handleTranslationResult(_ translation: String, isError: Bool = false) {
        translationView.updateTranslation(translation)
        translationView.stopTranslating()
        updateWindowSize()
    }
    
    // MARK: - 更新AI面板高度约束
    func updateAIHeightConstraint(_ height: CGFloat) {
        aiPanelHeightConstraint?.isActive = false
        aiPanelHeightConstraint = aiDetailExplanationPanel.heightAnchor.constraint(equalToConstant: height)
        aiPanelHeightConstraint?.isActive = true
        
        // 更新窗口大小
        updateWindowSize()
    }
    
    // MARK: - AI详细解释面板控制
    
    /// 显示AI详细解释面板
    func showAIDetailExplanationPanel() {
        aiDetailExplanationPanel.show()
        // 直接更新窗口大小，无动画
        updateWindowSize()
    }
    
    /// 隐藏AI详细解释面板
    func hideAIDetailExplanationPanel() {
        aiDetailExplanationPanel.hide()
        // 直接更新窗口大小，无动画
        updateWindowSize()
    }
    
    /// 更新AI详细解释面板内容
    func updateAIDetailExplanationContent(_ content: String) {
        // 如果AI面板已隐藏，则不更新内容
        guard aiDetailExplanationPanel.isVisible else {
            return
        }
        
        aiDetailExplanationPanel.updateContent(content)
        // updateWindowSize() 已在 showAIDetailExplanationPanel() 中调用
    }
    
    /// 设置AI分析内容（用于厂商切换时重新分析）
    func setAIAnalysisContent(_ content: String) {
        // 如果AI面板已隐藏，则不更新内容
        guard aiDetailExplanationPanel.isVisible else {
            return
        }
        
        aiDetailExplanationPanel.setAnalysisContent(content)
    }
    
    /// 切换AI详细解释面板显示状态
    func toggleAIDetailExplanationPanel() {
        if aiDetailExplanationPanel.isVisible {
            hideAIDetailExplanationPanel()
        } else {
            showAIDetailExplanationPanel()
        }
    }
    
    // 允许窗口成为关键窗口以保持可见
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    // 支持拖拽
    override func mouseDown(with event: NSEvent) {
        performDrag(with: event)
    }
    
    // 拖拽结束后更新位置记录
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        // 位置记录已移除，窗口位置由系统管理
    }
    
    
    
    // MARK: - 全局鼠标监听
    private func setupGlobalMouseMonitor() {
        // 窗口始终为固定状态，不需要外部点击隐藏逻辑
        // 保留方法以保持接口一致性，但不添加任何监听器
    }
    
    /// 开始截图操作，使用统一的截图服务
    func startScreenshotCapture() {
        // 使用统一的截图服务
        ScreenshotService.shared.startScreenshotCapture(source: .floatingResultWindow)
    }
    
    private func performOCR(on image: NSImage) {
        
        // 将NSImage转换为CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }
        
        
        // 创建Vision请求
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else { return }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                return
            }
            
            
            // 提取识别出的文本
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            // 清理文本，移除多余空格
            let cleanText = recognizedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                // 检查是否识别出文本
                if cleanText.isEmpty {
                    // 没有识别出文本，显示提醒
                    FloatingResultWindowManager.shared.showResultWindow(text: LocalizationManager.localized("no_text_detected"))
                } else {
                    // 通过FloatingResultWindowManager显示结果
                    FloatingResultWindowManager.shared.showResultWindow(text: cleanText)
                }
            }
        }
        
        // 设置识别参数
        request.recognitionLevel = .accurate  // 高精度识别
        request.usesLanguageCorrection = true // 启用语言纠正
        
        // 根据用户选择的源语言设置OCR识别语言
        let sourceLanguageCode = UserDefaults.standard.string(forKey: "AITransSourceLanguageCode")
        if let sourceLanguageCode = sourceLanguageCode {
            // 用户指定了具体语言，使用该语言进行识别
            request.automaticallyDetectsLanguage = false
            let ocrLanguageCode = mapToOCRLanguageCode(sourceLanguageCode)
            request.recognitionLanguages = [ocrLanguageCode]
        } else {
            // 用户选择自动检测，使用多语言识别
            request.automaticallyDetectsLanguage = true
            request.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant", "es-ES", "fr-FR", "de-DE", "pt-BR", "it-IT", "th-TH", "vi-VN"]
        }
        
        
        // 执行OCR识别
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            // OCR识别失败，忽略错误
        }
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
    
    private func checkScreenRecordingPermission() -> Bool {
        // 检查屏幕录制权限
        let screenCapturePermission = CGPreflightScreenCaptureAccess()
        return screenCapturePermission
    }
    
    /// 获取当前选中的单词
    /// - Returns: 选中的单词文本，如果没有选中则返回nil
    func getSelectedWord() -> String? {
        guard let tokenizedView = tokenizedContentView else { return nil }
        
        // 查找选中的单词按钮
        for button in tokenizedView.tokenButtons {
            if button.isWordSelected() {
                return button.token.text
            }
        }
        
        return nil
    }
    
}

// MARK: - 浮动结果窗口控制器
class FloatingResultWindowController: NSWindowController {
    init() {
        let window = FloatingResultWindow()
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
    }
}

// MARK: - 浮动结果窗口管理器
class FloatingResultWindowManager {
    static let shared: FloatingResultWindowManager = FloatingResultWindowManager()
    
    private var currentWindowController: FloatingResultWindowController?
    private let windowQueue = DispatchQueue(label: "com.aitrans.window", qos: .userInitiated)
    
    private init() {}
    
    func showResultWindow(text: String) {
        
        // 确保在主线程执行UI操作
        DispatchQueue.main.async { [weak self] in
            self?.performShowWindow(text: text)
        }
    }
    
    private func performShowWindow(text: String) {
        
        // 检查是否有现有窗口
        if let existingController = currentWindowController,
           let existingWindow = existingController.window as? FloatingResultWindow {
            
            // 窗口始终为固定状态，直接更新内容
            existingWindow.updateText(text)
            
            // 按钮状态在初始化时已设置，无需重复更新
            
            // 确保固定窗口保持可见
            existingWindow.orderFront(nil)
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // 没有现有窗口，创建新窗口
        currentWindowController = FloatingResultWindowController()
        
        // 安全地更新文本（窗口会在updateText中自动显示）
        if let windowController = currentWindowController,
           let window = windowController.window as? FloatingResultWindow {
            // 确保窗口配置正确
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            
            // 更新文本内容，窗口会在内容准备好后自动显示
            window.updateText(text)
        }
    }
    
    func hideResultWindow() {
        DispatchQueue.main.async { [weak self] in
            // 只隐藏窗口，不销毁实例
            if let window = self?.currentWindowController?.window {
                window.orderOut(nil)
            }
            
            // 同时隐藏AI详细解释面板
            if let window = self?.currentWindowController?.window as? FloatingResultWindow {
                window.hideAIDetailExplanationPanel()
            }
        }
    }
    
    /// 真正销毁窗口实例（仅在需要时调用）
    func destroyResultWindow() {
        DispatchQueue.main.async { [weak self] in
            // 关闭窗口并销毁实例
            self?.currentWindowController?.close()
            self?.currentWindowController = nil
            
            // 同时隐藏AI详细解释面板
            if let window = self?.currentWindowController?.window as? FloatingResultWindow {
                window.hideAIDetailExplanationPanel()
            }
        }
    }
    
    /// 获取当前窗口的源文本
    /// - Returns: 当前窗口的源文本，如果没有窗口则返回nil
    func getCurrentSourceText() -> String? {
        guard let window = currentWindowController?.window as? FloatingResultWindow else {
            return nil
        }
        return window.tokenizedContentView?.getSourceText()
    }
    
    /// 检查当前窗口是否固定
    /// - Returns: 始终返回true，窗口永远为固定状态
    func isCurrentWindowPinned() -> Bool {
        return true
    }
    
    /// 获取当前窗口
    /// - Returns: 当前窗口，如果没有窗口则返回nil
    func getCurrentWindow() -> FloatingResultWindow? {
        return currentWindowController?.window as? FloatingResultWindow
    }
    
    deinit {
        destroyResultWindow()
    }
}

