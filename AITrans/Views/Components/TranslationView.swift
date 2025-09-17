//
//  TranslationView.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import Cocoa
class TranslationView: NSView {
    private var centeredTextView: CenteredTextView!
    private var loadingIndicator: NSProgressIndicator!
    private var backButton: NSButton!
    private var bookButton: NSButton!
    private var isTranslating = false
    private var loadingTimer: Timer?
    private var isShowingWordTranslation = false
    private var fullTextTranslation: String = ""
    private var textViewLeadingConstraint: NSLayoutConstraint!
    private var backButtonWidthConstraint: NSLayoutConstraint!
    private var textViewTrailingConstraint: NSLayoutConstraint!
    
    // 详细解释面板相关属性
    private var isShowingDetailExplanation = false
    
    weak var parentWindow: FloatingResultWindow?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupNotifications()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 通知设置
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAIAnalysisNeedsLoading),
            name: NSNotification.Name("AIAnalysisNeedsLoading"),
            object: nil
        )
    }
    
    @objc private func handleAIAnalysisNeedsLoading() {
        showLoadingState()
    }
    
    private func setupView() {
        wantsLayer = true
        
        // 设置浅绿色背景
        layer?.backgroundColor = NSColor(red: 0.92, green: 0.98, blue: 0.92, alpha: 1.0).cgColor
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        
        // 添加边框与分词面板保持一致
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.systemGray.cgColor
        
        // 添加增强阴影 - 与分词视图完全一致
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow?.shadowOffset = NSSize(width: 0, height: -4)
        shadow?.shadowBlurRadius = 16
        
        // 创建返回按钮
        backButton = NSButton()
        
        // 尝试使用不同的SF Symbols图标名称
        if let image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "返回") {
            backButton.image = image
            backButton.imagePosition = .imageOnly
        } else if let image = NSImage(systemSymbolName: "arrow.left", accessibilityDescription: "返回") {
            backButton.image = image
            backButton.imagePosition = .imageOnly
        } else if let image = NSImage(systemSymbolName: "arrowshape.left", accessibilityDescription: "返回") {
            backButton.image = image
            backButton.imagePosition = .imageOnly
        } else {
            // 如果SF Symbols不可用，使用文本
            backButton.title = "←"
            backButton.font = NSFont.systemFont(ofSize: 16, weight: .bold)
            backButton.imagePosition = .noImage
        }
        backButton.isBordered = false
        backButton.wantsLayer = true
        backButton.layer?.backgroundColor = NSColor.clear.cgColor
        backButton.contentTintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.target = self
        backButton.action = #selector(backButtonClicked)
        backButton.isHidden = true // 默认隐藏
        
        // 设置返回按钮的内边距为0
        backButton.imageHugsTitle = true
        backButton.bezelStyle = .texturedSquare
        backButton.setButtonType(.momentaryPushIn)
        backButton.focusRingType = .none
        
        // 创建自定义的按钮样式，去除内边距
        let cell = backButton.cell as? NSButtonCell
        cell?.imageDimsWhenDisabled = false
        cell?.imageScaling = .scaleNone
        
        // 设置按钮内容边距为0
        backButton.wantsLayer = true
        if let layer = backButton.layer {
            layer.masksToBounds = false
        }
        
        // 创建图书按钮
        bookButton = NSButton()
        
        // 尝试使用图书相关的SF Symbols图标
        if let image = NSImage(systemSymbolName: "book", accessibilityDescription: "图书") {
            bookButton.image = image
            bookButton.imagePosition = .imageOnly
        } else if let image = NSImage(systemSymbolName: "book.closed", accessibilityDescription: "图书") {
            bookButton.image = image
            bookButton.imagePosition = .imageOnly
        } else if let image = NSImage(systemSymbolName: "text.book.closed", accessibilityDescription: "图书") {
            bookButton.image = image
            bookButton.imagePosition = .imageOnly
        } else {
            // 如果SF Symbols不可用，使用文本
            bookButton.title = "📚"
            bookButton.font = NSFont.systemFont(ofSize: 16, weight: .medium)
            bookButton.imagePosition = .noImage
        }
        bookButton.isBordered = false
        bookButton.wantsLayer = true
        bookButton.layer?.backgroundColor = NSColor.clear.cgColor
        bookButton.contentTintColor = .systemBlue
        bookButton.translatesAutoresizingMaskIntoConstraints = false
        bookButton.isHidden = false // 默认显示
        
        // 设置图书按钮样式
        bookButton.imageHugsTitle = true
        bookButton.bezelStyle = .texturedSquare
        bookButton.setButtonType(.momentaryPushIn)
        bookButton.focusRingType = .none
        
        // 创建自定义的按钮样式，去除内边距
        let bookCell = bookButton.cell as? NSButtonCell
        bookCell?.imageDimsWhenDisabled = false
        bookCell?.imageScaling = .scaleNone
        
        // 设置按钮内容边距为0
        bookButton.wantsLayer = true
        if let layer = bookButton.layer {
            layer.masksToBounds = false
        }
        
        // 设置图书按钮点击事件
        bookButton.target = self
        bookButton.action = #selector(bookButtonClicked)
        
        // 创建垂直居中文本视图
        centeredTextView = CenteredTextView()
        centeredTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建加载指示器
        loadingIndicator = NSProgressIndicator()
        loadingIndicator.style = .spinning
        loadingIndicator.isIndeterminate = true
        loadingIndicator.controlSize = .small
        loadingIndicator.isHidden = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backButton)
        addSubview(centeredTextView)
        addSubview(bookButton)
        addSubview(loadingIndicator)
        
        // 设置返回按钮约束
        backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        backButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        // 设置返回按钮宽度约束（用于动态调整）
        backButtonWidthConstraint = backButton.widthAnchor.constraint(equalToConstant: 24)  // 初始占位宽度
        backButtonWidthConstraint.isActive = true
        
        // 设置图书按钮约束（现在在最右边）
        bookButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
        bookButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        bookButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        bookButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        // 设置文本视图约束
        centeredTextView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        centeredTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        
        // 设置文本视图左侧约束（为返回按钮留出空间）
        textViewLeadingConstraint = centeredTextView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8)
        textViewLeadingConstraint.isActive = true
        
        // 设置文本视图右侧约束（为图书按钮留出空间）
        textViewTrailingConstraint = centeredTextView.trailingAnchor.constraint(equalTo: bookButton.leadingAnchor, constant: -8)
        textViewTrailingConstraint.isActive = true
        
        // 设置加载指示器约束
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func updateTranslation(_ translation: String) {
        centeredTextView.loadText(translation)
        
        // 保存全文翻译
        fullTextTranslation = translation
        isShowingWordTranslation = false
        
        // 隐藏返回按钮（保持占位）
        backButton.isHidden = true
        backButtonWidthConstraint.constant = 24  // 保持占位宽度
        // 文本视图左侧约束已经绑定到固定按钮，不需要调整
        
        // 更新翻译内容后调整窗口大小
        DispatchQueue.main.async { [weak self] in
            self?.parentWindow?.updateWindowSize()
        }
    }
    
    func showWordTranslation(_ wordTranslation: String) {
        centeredTextView.loadText(wordTranslation)
        
        // 显示返回按钮（占位）
        isShowingWordTranslation = true
        backButton.isHidden = false
        backButtonWidthConstraint.constant = 24  // 返回按钮宽度
        // 文本视图左侧约束已经绑定到固定按钮，不需要调整
        
        // 更新翻译内容后调整窗口大小
        DispatchQueue.main.async { [weak self] in
            self?.parentWindow?.updateWindowSize()
        }
    }
    
    @objc private func backButtonClicked() {
        
        // 隐藏返回按钮（保持占位）
        isShowingWordTranslation = false
        backButton.isHidden = true
        backButtonWidthConstraint.constant = 24  // 保持占位宽度
        // 文本视图左侧约束已经绑定到固定按钮，不需要调整
        
        // 隐藏AI详细解释面板（当点击返回按钮时）
        if let parentWindow = parentWindow {
            parentWindow.hideAIDetailExplanationPanel()
        }
        
        // 取消分词面板中所有单词的选择状态
        if let parentWindow = parentWindow,
           let tokenizedView = parentWindow.tokenizedContentView {
            tokenizedView.deselectAllWords()
        }
        
        // 重新翻译全文，使用当前的语言设置
        if let parentWindow = parentWindow {
            parentWindow.retranslateFullText()
        }
        
        // 调整窗口大小
        DispatchQueue.main.async { [weak self] in
            self?.parentWindow?.updateWindowSize()
        }
    }
    
    
    @objc private func bookButtonClicked() {
        
        // 显示AI分析窗口
        showAIAnalysisWindow()
    }
    
    // MARK: - AI分析窗口
    private func showAIAnalysisWindow() {
        // 显示AI详细解释面板（用于AI分析）
        parentWindow?.showAIDetailExplanationPanel()
        isShowingDetailExplanation = true
        
        // 检查是否有选中的单词
        let selectedWord = getSelectedWord()
        let isWordSelected = selectedWord != nil
        
        if isWordSelected {
            // 先设置原始分析内容到AI面板
            parentWindow?.setAIAnalysisContent(selectedWord!)
            
            // 获取目标语言设置
            let (_, targetLanguage) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
            // 分析选中的单词
            AIAnalysisService.shared.analyzeWord(selectedWord!, targetLanguage: targetLanguage) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let analysis):
                        // 设置分析后高度为400px
                        self?.parentWindow?.aiDetailExplanationPanel?.setHeight(400)
                        self?.updateAIContent(analysis)
                    case .failure(let error):
                        self?.showErrorState(error)
                    }
                }
            }
        } else {
            // 获取当前翻译的句子
            let currentSentence = getCurrentTranslationSentence()
            
            // 先设置原始分析内容到AI面板
            parentWindow?.setAIAnalysisContent(currentSentence)
            
            // 获取目标语言设置
            let (_, targetLanguage) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
            
            // 调用AI分析服务（内部会处理缓存检查）
            AIAnalysisService.shared.analyzeSentence(currentSentence, targetLanguage: targetLanguage) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let analysis):
                        // 设置分析后高度为400px
                        self?.parentWindow?.aiDetailExplanationPanel?.setHeight(400)
                        // 更新AI窗口内容
                        self?.updateAIContent(analysis)
                    case .failure(let error):
                        // 显示错误信息
                        self?.showErrorState(error)
                    }
                }
            }
        }
    }
    
    // MARK: - 获取选中的单词
    private func getSelectedWord() -> String? {
        guard let parentWindow = parentWindow else { return nil }
        
        // 调用FloatingResultWindow的公共方法
        return parentWindow.getSelectedWord()
    }
    
    // MARK: - 获取当前翻译句子
    private func getCurrentTranslationSentence() -> String {
        // 获取OCR识别的原始文本
        if let sourceText = FloatingResultWindowManager.shared.getCurrentSourceText(),
           !sourceText.isEmpty {
            return sourceText
        }
        
        // 如果没有OCR原始文本，返回默认文本
        return LocalizationManager.localized("please_retry_ocr")
    }
    
    // MARK: - 获取当前翻译文本
    func getCurrentTranslation() -> String {
        return centeredTextView.getText()
    }
    
    // MARK: - 显示加载状态
    private func showLoadingState() {
        // 分析开始时不改变高度，保持默认高度
        
        let loadingContent = """
        # ⚡ \(LocalizationManager.localized("ai_analyzing"))
        """
        
        parentWindow?.updateAIDetailExplanationContent(loadingContent)
    }
    
    // MARK: - 更新AI内容
    private func updateAIContent(_ analysis: String) {
        
        parentWindow?.updateAIDetailExplanationContent(analysis)
    }
    
    // MARK: - 显示错误状态
    private func showErrorState(_ error: Error) {
        let errorContent = """
        # ❌ \(LocalizationManager.localized("ai_analysis_failed"))
        
        **\(LocalizationManager.localized("error"))：** \(error.localizedDescription)
        
        ---
        
        **可能的原因：**
        - \(LocalizationManager.localized("network_error"))
        - \(LocalizationManager.localized("service_unavailable"))
        - \(LocalizationManager.localized("request_format_error"))
        
        **建议操作：**
        1. 检查网络连接
        2. 稍后重试
        3. 联系技术支持
        
        ---
        
        *\(LocalizationManager.localized("please_retry_later"))*
        """
        
        parentWindow?.updateAIDetailExplanationContent(errorContent)
    }
    
    private func toggleDetailExplanationPanel() {
        if isShowingDetailExplanation {
            hideDetailExplanationPanel()
        } else {
            showDetailExplanationPanel()
        }
    }
    
    private func showDetailExplanationPanel() {
        // 显示AI详细解释面板
        parentWindow?.showAIDetailExplanationPanel()
        isShowingDetailExplanation = true
        
        // 更新解释内容
        updateDetailExplanationContent()
    }
    
    private func hideDetailExplanationPanel() {
        // 隐藏AI详细解释面板
        parentWindow?.hideAIDetailExplanationPanel()
        isShowingDetailExplanation = false
    }
    
    private func updateDetailExplanationContent() {
        // 这里可以添加获取详细解释内容的逻辑
        // 例如：从翻译服务获取更详细的解释
        let sampleExplanation = """
        这是一个示例的详细解释内容。
        
        这里可以包含：
        • 词汇的详细释义
        • 语法结构分析
        • 使用场景和例句
        • 同义词和反义词
        • 词源和历史背景
        
        面板支持滚动查看长内容，并且会自动调整高度以适应内容。
        """
        
        // 更新详细解释面板的内容
        parentWindow?.updateAIDetailExplanationContent(sampleExplanation)
    }
    
    func startTranslating() {
        isTranslating = true
        
        // 取消之前的定时器
        loadingTimer?.invalidate()
        loadingTimer = nil
        
        // 立即显示加载动画，但使用淡入效果
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 设置初始状态
            self.loadingIndicator.alphaValue = 0.0
            self.loadingIndicator.isHidden = false
            self.loadingIndicator.startAnimation(nil)
            
            // 淡入动画
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                context.allowsImplicitAnimation = true
                self.loadingIndicator.alphaValue = 1.0
            }
            
        }
    }
    
    func stopTranslating() {
        isTranslating = false
        
        // 取消定时器
        loadingTimer?.invalidate()
        loadingTimer = nil
        
        // 淡出动画后隐藏等待图标
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            self.loadingIndicator.alphaValue = 0.0
        }) {
            self.loadingIndicator.isHidden = true
            self.loadingIndicator.stopAnimation(nil)
        }
    }
    
    func fittingSize() -> NSSize {
        if isTranslating {
            return NSSize(width: 0, height: 60) // 加载状态的高度，取消最小宽度限制
        }
        
        let textSize = centeredTextView.fittingSize()
        
        // 计算所有按钮和间距的宽度
        var totalButtonWidth: CGFloat = 0
        var totalSpacing: CGFloat = 0
        
        // 图书按钮（始终显示，现在在最右边）
        let bookButtonWidth: CGFloat = 24
        let bookButtonSpacing: CGFloat = 8  // 图书按钮与文本的间距
        
        // 返回按钮（始终占位）
        let backButtonWidth: CGFloat = 24  // 返回按钮宽度
        let backButtonSpacing: CGFloat = 8  // 返回按钮与文本的间距
        
        // 计算总宽度
        totalButtonWidth = backButtonWidth + bookButtonWidth
        totalSpacing = backButtonSpacing + bookButtonSpacing
        
        // 左右边距
        let horizontalPadding: CGFloat = 16  // 8px 左边距 + 8px 右边距
        
        return NSSize(
            width: textSize.width + totalButtonWidth + totalSpacing + horizontalPadding,
            height: textSize.height
        )
    }
}

// MARK: - 分词显示视图
