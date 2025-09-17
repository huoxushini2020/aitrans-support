//
//  AIDetailExplanationPanel.swift
//  AITrans
//
//  Created by LEO on 12/9/2568 BE.
//

import AppKit
import WebKit

// MARK: - 字符扩展
extension Character {
    var isChinese: Bool {
        return "\u{4e00}" <= self && self <= "\u{9fff}"
    }
}

// MARK: - AI详细解释面板
class AIDetailExplanationPanel: NSView {
    
    // MARK: - 属性
    private var titleLabel: NSTextField!
    private var webView: WKWebView!
    var closeButton: NSButton! // 改为internal，供DragOverlayView访问
    private var dragOverlayView: NSView!
    var aiProviderPopUpButton: NSPopUpButton! // 改为internal，供DragOverlayView访问
    var isVisible = false
    
    // 父窗口引用，用于访问固定状态
    weak var parentWindow: FloatingResultWindow?
    
    // MARK: - 渲染优化属性
    private var lastContent: String = ""
    private var contentCache: [String: String] = [:]
    private var currentAnalysisContent: String = "" // 当前分析的内容
    private var renderTimer: Timer?
    
    // MARK: - 高度常量
    private let normalHeight: CGFloat = 400.0
    private let defaultHeight: CGFloat = 80.0
    
    // MARK: - 拖拽相关属性
    private var initialLocation: NSPoint = .zero
    private var initialWindowOrigin: NSPoint = .zero
    
    // MARK: - 初始化
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        setupMouseEvents()
        // 默认隐藏面板
        isVisible = false
        alphaValue = 0.0
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupMouseEvents()
        // 默认隐藏面板
        isVisible = false
        alphaValue = 0.0
    }
    
    deinit {
        // 清理资源
        renderTimer?.invalidate()
        renderTimer = nil
        contentCache.removeAll()
    }
    
    // MARK: - 视图设置
    private func setupView() {
        wantsLayer = true
        
        // 设置面板样式 - 浅蓝色背景
        layer?.backgroundColor = NSColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0).cgColor
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        
        // 添加边框与分词面板保持一致
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.systemGray.cgColor
        
        // 添加增强阴影
        shadow = NSShadow()
        shadow?.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow?.shadowOffset = NSSize(width: 0, height: -4)
        shadow?.shadowBlurRadius = 16
        
        // 鼠标事件支持通过重写acceptsFirstMouse方法实现
        
        setupSubviews()
        setupConstraints()
        setupDragOverlay()
    }
    
    private func setupSubviews() {
        // 创建标题标签
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleLabel.stringValue = "📚 \(LocalizationManager.localized("ai_detailed_explanation"))"
        addSubview(titleLabel)
        
        // 创建AI厂商下拉列表框
        aiProviderPopUpButton = NSPopUpButton()
        aiProviderPopUpButton.translatesAutoresizingMaskIntoConstraints = false
        aiProviderPopUpButton.pullsDown = false
        aiProviderPopUpButton.autoenablesItems = true
        aiProviderPopUpButton.font = NSFont.systemFont(ofSize: 12)
        aiProviderPopUpButton.target = self
        aiProviderPopUpButton.action = #selector(aiProviderChanged(_:))
        
        // 添加厂商选项
        let providers = getAIProviders()
        aiProviderPopUpButton.removeAllItems()
        for provider in providers {
            aiProviderPopUpButton.addItem(withTitle: provider)
        }
        aiProviderPopUpButton.selectItem(at: 0) // 默认选择第一个
        
        addSubview(aiProviderPopUpButton)
        
        // 创建关闭按钮
        closeButton = NSButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.isBordered = false
        closeButton.wantsLayer = true
        closeButton.layer?.backgroundColor = NSColor.clear.cgColor
        closeButton.contentTintColor = .systemGray
        
        // 设置关闭按钮图标
        if let image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "关闭") {
            closeButton.image = image
            closeButton.imagePosition = .imageOnly
        } else {
            closeButton.title = "✕"
            closeButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            closeButton.imagePosition = .noImage
        }
        
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        addSubview(closeButton)
        
        // 创建WKWebView用于渲染Markdown
        let webConfiguration = WKWebViewConfiguration()
        // 使用新的API设置JavaScript支持
        if #available(macOS 11.0, *) {
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            webConfiguration.preferences.javaScriptEnabled = true
        }
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // 设置背景透明
        webView.setValue(false, forKey: "drawsBackground")
        webView.setValue(NSColor.clear, forKey: "backgroundColor")
        
        // 禁用WebView的鼠标事件拦截，让父视图处理拖动
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        
        // 立即配置滚动视图，隐藏系统滚动条
        configureScrollView()
        
        addSubview(webView)
        
        // 创建拖动覆盖层
        dragOverlayView = NSView()
        dragOverlayView.translatesAutoresizingMaskIntoConstraints = false
        dragOverlayView.wantsLayer = true
        dragOverlayView.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(dragOverlayView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 标题标签约束
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: aiProviderPopUpButton.leadingAnchor, constant: -8),
            
            // AI厂商下拉列表框约束
            aiProviderPopUpButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            aiProviderPopUpButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            aiProviderPopUpButton.widthAnchor.constraint(equalToConstant: 120),
            aiProviderPopUpButton.heightAnchor.constraint(equalToConstant: 24),
            
            // 关闭按钮约束
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20),
            
            // WebView约束
            webView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // 拖动覆盖层约束 - 只覆盖标题标签区域，不阻挡AI厂商选择器和关闭按钮
            dragOverlayView.topAnchor.constraint(equalTo: topAnchor),
            dragOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dragOverlayView.trailingAnchor.constraint(equalTo: aiProviderPopUpButton.leadingAnchor, constant: -8),
            dragOverlayView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }
    
    // MARK: - 滚动视图配置
    private func configureScrollView() {
        guard let scrollView = webView.enclosingScrollView else {
            return
        }
        
        // 启用系统滚动条，禁用WebView内部滚动
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        
        // 启用滚动弹性
        scrollView.verticalScrollElasticity = .allowed
        scrollView.horizontalScrollElasticity = .none
        
        // 启用动态滚动
        scrollView.scrollsDynamically = true
        
        // 显示滚动条
        scrollView.verticalScroller?.isHidden = false
        scrollView.horizontalScroller?.isHidden = true
        
        // 设置滚动条样式
        scrollView.verticalScroller?.alphaValue = 1.0
        scrollView.horizontalScroller?.alphaValue = 0.0
    }
    
    private func forceShowScrollbar() {
        // 现在只使用WebView内部滚动条，不需要配置系统滚动条
        // 通过JavaScript确保WebView内部滚动条可见
        injectScrollbarJavaScript()
    }
    
    // MARK: - 强制显示滚动条的JavaScript方法
    private func injectScrollbarJavaScript() {
        let script = """
        (function() {
            // 禁用WebView内部滚动，只使用系统滚动条
            document.body.style.overflow = 'visible';
            
            // 确保html元素也不产生滚动条
            if (document.documentElement) {
                document.documentElement.style.overflow = 'visible';
            }
            
            // 确保容器元素不产生滚动条
            var container = document.querySelector('.container');
            if (container) {
                container.style.overflow = 'visible';
            }
            
            // 添加样式完全隐藏WebView内部滚动条
            var style = document.createElement('style');
            style.textContent = `
                /* 完全隐藏WebView内部滚动条 */
                ::-webkit-scrollbar {
                    display: none !important;
                    width: 0 !important;
                    height: 0 !important;
                }
                ::-webkit-scrollbar-track {
                    display: none !important;
                }
                ::-webkit-scrollbar-thumb {
                    display: none !important;
                }
                ::-webkit-scrollbar-corner {
                    display: none !important;
                }
                /* 隐藏Firefox滚动条 */
                * {
                    scrollbar-width: none !important;
                    scrollbar-color: transparent transparent !important;
                }
                /* 确保body不产生滚动条 */
                body {
                    overflow: visible !important;
                }
            `;
            document.head.appendChild(style);
            
            // 返回成功状态，避免WKErrorDomain Code=5错误
            return 'scrollbar_configuration_complete';
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript执行错误: \(error)")
            } else if let result = result as? String {
                print("✅ JavaScript执行成功: \(result)")
            }
        }
    }
    
    // MARK: - 鼠标事件设置
    private func setupMouseEvents() {
        // 启用鼠标事件
        wantsLayer = true
        layer?.masksToBounds = true
        
        // 添加鼠标跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - 鼠标事件处理（滚动条控制）
    
    override func scrollWheel(with event: NSEvent) {
        // 处理鼠标滚轮事件
        if event.phase == .changed {
            let deltaY = event.scrollingDeltaY
            let scrollView = webView.enclosingScrollView
            
            if let scrollView = scrollView {
                // 计算新的滚动位置
                let currentOffset = scrollView.contentView.bounds.origin.y
                let newOffset = max(0, currentOffset - deltaY)
                
                // 设置滚动位置
                let newPoint = NSPoint(x: 0, y: newOffset)
                scrollView.contentView.scroll(to: newPoint)
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
    }
    
    // MARK: - 事件处理
    @objc private func closeButtonClicked() {
        // 窗口始终为固定状态，无需取消
        
        hide()
    }
    
    // MARK: - 鼠标事件支持
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    // MARK: - 拖拽事件处理
    override func mouseDown(with event: NSEvent) {
        // 检查是否点击在关闭按钮上
        let locationInView = convert(event.locationInWindow, from: nil)
        let closeButtonFrame = closeButton.frame
        
        // 如果点击在关闭按钮上，不开始拖拽
        if closeButtonFrame.contains(locationInView) {
            return
        }
        
        // 记录初始位置 - 使用屏幕坐标
        initialLocation = NSEvent.mouseLocation
        initialWindowOrigin = self.window?.frame.origin ?? .zero
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        
        // 使用屏幕坐标进行更流畅的拖拽
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y
        
        let newOrigin = NSPoint(
            x: initialWindowOrigin.x + deltaX,
            y: initialWindowOrigin.y + deltaY
        )
        
        // 使用更流畅的窗口移动方式
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.0  // 立即移动，保持流畅
            context.allowsImplicitAnimation = false
            window.setFrameOrigin(newOrigin)
        }
    }
    
    // MARK: - 拖动覆盖层事件处理
    private func setupDragOverlay() {
        // 创建自定义拖动覆盖层
        let dragOverlay = DragOverlayView()
        dragOverlay.parentPanel = self
        dragOverlay.translatesAutoresizingMaskIntoConstraints = false
        dragOverlay.wantsLayer = true
        dragOverlay.layer?.backgroundColor = NSColor.clear.cgColor
        
        // 替换原来的拖动覆盖层
        dragOverlayView.removeFromSuperview()
        dragOverlayView = dragOverlay
        addSubview(dragOverlayView)
        
        // 重新设置约束 - 只覆盖标题标签区域，不阻挡AI厂商选择器和关闭按钮
        NSLayoutConstraint.activate([
            dragOverlayView.topAnchor.constraint(equalTo: topAnchor),
            dragOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dragOverlayView.trailingAnchor.constraint(equalTo: aiProviderPopUpButton.leadingAnchor, constant: -8),
            dragOverlayView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        // 鼠标进入时显示滚动条
        if let scrollView = webView.enclosingScrollView {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                scrollView.verticalScroller?.alphaValue = 1.0
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // 鼠标离开时隐藏滚动条
        if let scrollView = webView.enclosingScrollView {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                scrollView.verticalScroller?.alphaValue = 0.0
            }
        }
    }
    
    // MARK: - 内容更新
    func updateContent(_ content: String) {
        // 强制清除缓存，确保新样式生效
        contentCache = [:]
        lastContent = ""
        
        // 防抖处理：取消之前的定时器
        renderTimer?.invalidate()
        
        // 设置新的定时器，避免快速连续渲染
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.performRender(content)
        }
    }
    
    // MARK: - 设置分析内容
    func setAnalysisContent(_ content: String) {
        // 保存当前分析内容，用于厂商切换时重新分析
        currentAnalysisContent = content
        print("📝 设置分析内容: \(content.prefix(30))...")
    }
    
    // MARK: - 执行渲染
    private func performRender(_ content: String) {
        // 检查缓存
        if let cachedHTML = contentCache[content] {
            webView.loadHTMLString(cachedHTML, baseURL: nil)
            lastContent = content
            return
        }
        
        // 异步渲染，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let htmlContent = self.createHTMLContent(from: content)
            
            // 缓存HTML内容
            self.contentCache[content] = htmlContent
            
            // 限制缓存大小，避免内存泄漏
            if self.contentCache.count > 10 {
                let keysToRemove = Array(self.contentCache.keys.prefix(5))
                for key in keysToRemove {
                    self.contentCache.removeValue(forKey: key)
                }
            }
            
            DispatchQueue.main.async {
                self.webView.loadHTMLString(htmlContent, baseURL: nil)
                self.lastContent = content
                
                // 延迟配置滚动条，确保内容加载完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.configureScrollView()
                    self.injectScrollbarJavaScript()
                }
            }
        }
    }
    
    // MARK: - 创建HTML内容
    private func createHTMLContent(from markdown: String) -> String {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                \(getCSSStyles())
            </style>
        </head>
        <body>
            <div class="container">
                \(convertMarkdownToHTML(markdown))
            </div>
        </body>
        </html>
        """
        return htmlContent
    }
    
    // MARK: - 获取CSS样式
    private func getCSSStyles() -> String {
        return """
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background: transparent;
            padding: 0;
            margin: 0;
            height: auto;
            width: 100%;
            overflow: visible;
            box-sizing: border-box;
            position: relative;
            font-size: 15px;
        }
        
        /* 隐藏所有滚动条，只使用系统默认 */
        ::-webkit-scrollbar {
            display: none !important;
        }
        
        * {
            scrollbar-width: none !important;
        }
        
        .container {
            width: 100%;
            height: 100%;
            background: transparent;
            padding: 0;
            margin: 0;
            box-sizing: border-box;
            position: relative;
            overflow: visible;
        }
        
        h1 {
            font-size: 20px;
            font-weight: 600;
            color: #1a365d;
            margin: 0 0 12px 0;
            padding: 0;
            width: 100%;
            text-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        
        h2 {
            font-size: 18px;
            font-weight: 500;
            color: #2d3748;
            margin: 16px 0 8px 0;
            padding: 0;
            width: 100%;
            text-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        
        h3 {
            font-size: 16px;
            font-weight: 500;
            color: #4a5568;
            margin: 12px 0 6px 0;
            padding: 0;
            width: 100%;
            text-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        
        p {
            font-size: 15px;
            color: #2d3748;
            margin: 0 0 8px 0;
            padding: 0;
            line-height: 1.5;
            width: 100%;
        }
        
        ul, ol {
            font-size: 15px;
            color: #2d3748;
            margin: 0 0 8px 0;
            padding: 0;
            width: 100%;
        }
        
        li {
            margin: 2px 0;
            line-height: 1.4;
            color: #2d3748;
        }
        
        strong {
            font-weight: 600;
            color: #1a365d;
            text-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }
        
        em {
            font-style: italic;
            color: #4a5568;
        }
        
        code {
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            font-size: 12px;
            background-color: #e2e8f0;
            color: #c53030;
            padding: 2px 4px;
            border-radius: 3px;
            border: 1px solid #cbd5e0;
        }
        
        pre {
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            font-size: 12px;
            background-color: #e2e8f0;
            color: #1a365d;
            padding: 8px;
            border-radius: 4px;
            border: 1px solid #cbd5e0;
            margin: 8px 0;
            overflow-x: auto;
        }
        
        blockquote {
            border-left: 4px solid #3182ce;
            margin: 16px 0;
            padding: 8px 16px;
            background-color: #ebf8ff;
            color: #2d3748;
            font-style: italic;
            border-radius: 0 4px 4px 0;
        }
        
        hr {
            border: none;
            height: 2px;
            background: linear-gradient(to right, #3182ce, #63b3ed, #3182ce);
            margin: 16px 0;
            border-radius: 1px;
        }
        
        /* 特殊文本样式 */
        .pronunciation {
            color: #d53f8c;
            font-weight: 600;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
        }
        
        .part-of-speech {
            color: #38a169;
            font-weight: 600;
            background-color: #f0fff4;
            padding: 2px 6px;
            border-radius: 3px;
            border: 1px solid #9ae6b4;
        }
        
        .meaning {
            color: #2b6cb0;
            font-weight: 500;
        }
        
        .example {
            color: #744210;
            background-color: #fefcbf;
            padding: 4px 8px;
            border-radius: 4px;
            border-left: 3px solid #f6e05e;
        }
        
        .synonym {
            color: #553c9a;
            font-weight: 500;
        }
        
        .antonym {
            color: #c53030;
            font-weight: 500;
        }
        """
    }
    
    // MARK: - 转换Markdown为HTML
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // 预处理：去除多余空行，统一换行符
        let cleanedMarkdown = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 按行处理
        let lines = cleanedMarkdown.components(separatedBy: "\n")
        var processedLines: [String] = []
        var inList = false
        
        for (_, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                continue
            }
            
            // 跳过带有编号的标题行（如 "## 1. 单词发音音标"）
            if trimmedLine.hasPrefix("###") && !trimmedLine.hasPrefix("####") {
                let title = String(trimmedLine.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                // 检查是否包含数字编号，如果包含则跳过整行
                if title.range(of: "^\\d+\\.\\s*", options: .regularExpression) != nil {
                    continue  // 跳过带有编号的标题行
                }
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                processedLines.append("<h3>\(title)</h3>")
            } else if trimmedLine.hasPrefix("##") && !trimmedLine.hasPrefix("###") {
                let title = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                // 检查是否包含数字编号，如果包含则跳过整行
                if title.range(of: "^\\d+\\.\\s*", options: .regularExpression) != nil {
                    continue  // 跳过带有编号的标题行
                }
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                processedLines.append("<h2>\(title)</h2>")
            } else if trimmedLine.hasPrefix("#") && !trimmedLine.hasPrefix("##") {
                let title = String(trimmedLine.dropFirst(1)).trimmingCharacters(in: .whitespacesAndNewlines)
                // 检查是否包含数字编号，如果包含则跳过整行
                if title.range(of: "^\\d+\\.\\s*", options: .regularExpression) != nil {
                    continue  // 跳过带有编号的标题行
                }
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                processedLines.append("<h1>\(title)</h1>")
            }
            // 转换列表项（必须在一行开头）
            else if (trimmedLine.hasPrefix("-") || trimmedLine.hasPrefix("*")) && trimmedLine.count > 1 {
                let listItem = String(trimmedLine.dropFirst(1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !inList {
                    processedLines.append("<ul>")
                    inList = true
                }
                processedLines.append("<li>\(listItem)</li>")
            }
            // 普通文本
            else {
                if inList {
                    processedLines.append("</ul>")
                    inList = false
                }
                processedLines.append(trimmedLine)
            }
        }
        
        // 结束未关闭的列表
        if inList {
            processedLines.append("</ul>")
        }
        
        // 合并处理后的行，去掉所有空行
        var html = processedLines.filter { !$0.isEmpty }.joined(separator: "")
        
        // 转换粗体和斜体，并添加特殊样式
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        
        // 为特定内容添加CSS类
        html = addColorClasses(html)
        
        // 转换代码
        html = html.replacingOccurrences(of: "`(.+?)`", with: "<code>$1</code>", options: .regularExpression)
        
        // 处理段落，让内容更紧凑
        let htmlLines = html.components(separatedBy: "\n")
        var compactLines: [String] = []
        var currentParagraph = ""
        
        for line in htmlLines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue  // 跳过空行
            } else if trimmed.hasPrefix("<") {
                // 如果有待处理的段落，先处理它
                if !currentParagraph.isEmpty {
                    compactLines.append("<p>\(currentParagraph)</p>")
                    currentParagraph = ""
                }
                compactLines.append(trimmed)
            } else {
                // 累积段落内容
                if !currentParagraph.isEmpty {
                    currentParagraph += " " + trimmed
                } else {
                    currentParagraph = trimmed
                }
            }
        }
        
        // 处理最后一个段落
        if !currentParagraph.isEmpty {
            compactLines.append("<p>\(currentParagraph)</p>")
        }
        
        // 合并所有内容，不使用换行符
        html = compactLines.joined(separator: "")
        
        return html
    }
    
    // MARK: - 添加颜色样式类
    private func addColorClasses(_ html: String) -> String {
        var coloredHtml = html
        
        // 为音标添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(国际音标\\(IPA\\)|音标|发音):\\s*([^<]+)",
            with: "$1: <span class=\"pronunciation\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 为词性添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(词性|词类|词性标签):\\s*([^<]+)",
            with: "$1: <span class=\"part-of-speech\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 为含义添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(含义|释义|意思|定义):\\s*([^<]+)",
            with: "$1: <span class=\"meaning\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 为例句添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(例句|例子|示例):\\s*([^<]+)",
            with: "$1: <span class=\"example\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 为同义词添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(同义词|近义词):\\s*([^<]+)",
            with: "$1: <span class=\"synonym\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        // 为反义词添加样式
        coloredHtml = coloredHtml.replacingOccurrences(
            of: "(反义词|反义):\\s*([^<]+)",
            with: "$1: <span class=\"antonym\">$2</span>",
            options: [.regularExpression, .caseInsensitive]
        )
        
        return coloredHtml
    }
    
    // MARK: - AI厂商相关方法
    private func getAIProviders() -> [String] {
        // 只返回启用的厂商名称
        return AIAPIKeyManager.shared.getEnabledProviders().map { $0.name }
    }
    
    @objc private func aiProviderChanged(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        let selectedProvider = sender.titleOfSelectedItem ?? "智谱AI (Zhipu AI)"
        
        print("🔄 AI厂商已切换为: \(selectedProvider) (索引: \(selectedIndex))")
        
        // 获取选中的厂商配置
        if let config = AIAPIKeyManager.shared.getProviderConfig(by: selectedProvider) {
            print("📋 API配置: \(config.apiUrl)")
            print("⚡ 模型: \(config.model)")
            print("✅ 状态: \(config.enabled ? "启用" : "禁用")")
            
            // 获取厂商key
            let providerKey = getProviderKey(by: config.name)
            if let key = providerKey {
                // 验证API密钥（使用厂商key而不是名称）
                if AIAPIKeyManager.shared.validateAPIKey(for: key) {
                    print("🔑 API密钥验证成功")
                    print("🔍 开始处理厂商切换: \(selectedProvider) -> \(key)")
                    
                    // 立即保存用户选择为默认厂商
                    saveUserChoiceAsDefault(key: key, name: selectedProvider)
                    
                    // 发送通知，让AIAnalysisService处理厂商切换
                    updateAIServiceConfiguration(config)
                    
                    // 立即更新UI显示
                    updateUIForProviderChange(providerName: selectedProvider)
                    
                    // 自动触发AI分析
                    triggerAutoAIAnalysis()
                    
                    print("✅ 厂商切换完成: \(selectedProvider) -> \(key)")
                } else {
                    print("❌ API密钥验证失败或未配置")
                    // 显示错误提示
                    showProviderError(LocalizationManager.localized("api_key_validation_failed"))
                }
            } else {
                print("❌ 无法找到厂商key: \(config.name)")
                showProviderError(LocalizationManager.localized("provider_switch_error"))
            }
        } else {
            print("❌ 无法获取厂商配置: \(selectedProvider)")
            showProviderError(LocalizationManager.localized("provider_switch_error"))
        }
    }
    
    // MARK: - 保存用户选择为默认厂商
    private func saveUserChoiceAsDefault(key: String, name: String) {
        print("🔍 开始保存用户选择为默认厂商: \(name) (\(key))")
        
        // 检查是否启用自动保存用户选择
        let configManager = AIPromptConfigManager.shared
        let defaultProvider = configManager.getDefaultAIProvider()
        
        print("📋 当前默认厂商: \(defaultProvider.name) (\(defaultProvider.key))")
        print("🔄 用户选择厂商: \(name) (\(key))")
        
        // 如果用户选择与当前默认不同，则更新
        if defaultProvider.key != key {
            print("🔄 厂商不同，开始更新默认厂商...")
            configManager.setDefaultAIProvider(key: key, name: name)
            
            // 验证保存结果
            let savedDefault = configManager.getDefaultAIProvider()
            print("🔍 保存后验证: \(savedDefault.name) (\(savedDefault.key))")
            
            if savedDefault.key == key && savedDefault.name == name {
                print("✅ 默认厂商保存成功！")
            } else {
                print("❌ 默认厂商保存失败！")
            }
        } else {
            print("ℹ️ 用户选择与当前默认厂商相同，无需更新")
        }
    }
    
    // MARK: - 获取厂商key的映射
    private func getProviderKey(by name: String) -> String? {
        switch name {
        case "智谱AI (Zhipu AI)":
            return "zhipu_ai"
        case "Google Gemini 2.5 Flash":
            return "gemini"
        case "OpenAI GPT":
            return "openai"
        case "Claude (Anthropic)":
            return "claude"
        case "百度文心一言":
            return "baidu"
        case "阿里通义千问":
            return "alibaba"
        case "腾讯混元":
            return "tencent"
        case "字节豆包":
            return "doubao"
        default:
            return nil
        }
    }
    
    // MARK: - 显示厂商错误提示
    private func showProviderError(_ message: String) {
        // 可以在这里添加错误提示UI
        print("⚠️ 厂商切换错误: \(message)")
    }
    
    // MARK: - 同步当前厂商
    private func syncCurrentProvider() {
        // 刷新厂商列表
        refreshProviderList()
        
        // 优先从配置文件读取默认厂商
        let configManager = AIPromptConfigManager.shared
        let defaultProvider = configManager.getDefaultAIProvider()
        
        // 如果配置文件中有默认厂商，使用它
        if !defaultProvider.key.isEmpty {
            AIAnalysisService.shared.setCurrentProvider(defaultProvider.key)
            let providerName = defaultProvider.name
            
            if let index = getAIProviders().firstIndex(of: providerName) {
                aiProviderPopUpButton.selectItem(at: index)
                print("🔄 已同步AI厂商选择器为默认厂商: \(providerName)")
            } else {
                print("⚠️ 默认厂商不在可用列表中: \(providerName)")
                // 回退到当前服务中的厂商
                syncCurrentProviderFromService()
            }
        } else {
            // 回退到当前服务中的厂商
            syncCurrentProviderFromService()
        }
    }
    
    // MARK: - 从服务同步当前厂商
    private func syncCurrentProviderFromService() {
        let currentProvider = AIAnalysisService.shared.getCurrentProvider()
        let providerName = getProviderName(by: currentProvider)
        
        if let index = getAIProviders().firstIndex(of: providerName) {
            aiProviderPopUpButton.selectItem(at: index)
            print("🔄 已同步AI厂商选择器: \(providerName)")
        } else {
            print("⚠️ 无法找到当前厂商: \(currentProvider)")
        }
    }
    
    // MARK: - 刷新厂商列表
    private func refreshProviderList() {
        let providers = getAIProviders()
        aiProviderPopUpButton.removeAllItems()
        for provider in providers {
            aiProviderPopUpButton.addItem(withTitle: provider)
        }
        
        print("🔄 已刷新AI厂商列表，共 \(providers.count) 个厂商:")
        for (index, provider) in providers.enumerated() {
            print("  \(index): \(provider)")
        }
    }
    
    // MARK: - 根据key获取厂商名称
    private func getProviderName(by key: String) -> String {
        switch key {
        case "zhipu_ai":
            return "智谱AI (Zhipu AI)"
        case "gemini":
            return "Google Gemini 2.5 Flash"
        case "openai":
            return "OpenAI GPT"
        case "claude":
            return "Claude (Anthropic)"
        case "baidu":
            return "百度文心一言"
        case "alibaba":
            return "阿里通义千问"
        case "tencent":
            return "腾讯混元"
        case "doubao":
            return "字节豆包"
        default:
            return "智谱AI (Zhipu AI)" // 默认返回智谱AI
        }
    }
    
    // MARK: - 更新AI服务配置
    private func updateAIServiceConfiguration(_ config: AIAPIKeyManager.AIProviderConfig) {
        // 通知AIAnalysisService更新配置
        NotificationCenter.default.post(
            name: NSNotification.Name("AIProviderChanged"),
            object: nil,
            userInfo: ["config": config]
        )
    }
    
    // MARK: - 更新UI显示
    private func updateUIForProviderChange(providerName: String) {
        // 确保下拉选择器显示正确的选中项
        if let index = getAIProviders().firstIndex(of: providerName) {
            aiProviderPopUpButton.selectItem(at: index)
            print("🔄 UI已更新为选中厂商: \(providerName)")
        }
        
        // 可以在这里添加其他UI更新逻辑
        // 比如更新标题栏显示、状态指示器等
    }
    
    // MARK: - 自动触发AI分析
    private func triggerAutoAIAnalysis() {
        print("⚡ 开始自动AI分析...")
        
        // 延迟一点时间，确保厂商切换完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performAutoAIAnalysis()
        }
    }
    
    // MARK: - 执行自动AI分析
    private func performAutoAIAnalysis() {
        // 检查面板是否可见
        guard isVisible else {
            print("ℹ️ AI面板已隐藏，跳过自动AI分析")
            return
        }
        
        // 检查是否有当前内容需要分析
        guard !currentAnalysisContent.isEmpty else {
            print("ℹ️ 没有内容需要分析，跳过自动AI分析")
            return
        }
        
        print("🔍 开始分析内容: \(currentAnalysisContent.prefix(50))...")
        
        // 显示加载状态
        showLoadingState()
        
        // 判断是单词还是句子分析
        let isWordSelected = isCurrentContentWord()
        
        // 获取目标语言设置
        let (_, targetLanguage) = parentWindow?.getLanguageSettings() ?? ("auto", "zh")
        
        // 调用AI分析服务
        if isWordSelected {
            AIAnalysisService.shared.analyzeWord(currentAnalysisContent, targetLanguage: targetLanguage) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAIAnalysisResult(result)
                }
            }
        } else {
            AIAnalysisService.shared.analyzeSentence(currentAnalysisContent, targetLanguage: targetLanguage) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAIAnalysisResult(result)
                }
            }
        }
    }
    
    // MARK: - 判断当前内容是否为单词
    private func isCurrentContentWord() -> Bool {
        let trimmedContent = currentAnalysisContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 改进的单词判断逻辑：
        // 1. 不包含空格
        // 2. 长度较短（小于20个字符）
        // 3. 不包含中文标点符号（？。！，、；：）
        // 4. 不包含多个中文字符（中文句子通常有多个字符）
        
        let hasSpaces = trimmedContent.contains(" ")
        let isShort = trimmedContent.count < 20
        let hasChinesePunctuation = trimmedContent.range(of: "[？。！，、；：]", options: .regularExpression) != nil
        let chineseCharCount = trimmedContent.components(separatedBy: .whitespacesAndNewlines).joined().filter { $0.isChinese }.count
        
        // 如果是中文内容且字符数大于3，很可能是句子
        if chineseCharCount > 3 {
            return false
        }
        
        // 如果包含中文标点符号，是句子
        if hasChinesePunctuation {
            return false
        }
        
        // 如果包含空格，是句子
        if hasSpaces {
            return false
        }
        
        // 其他情况按长度判断
        return isShort
    }
    
    // MARK: - 处理AI分析结果
    private func handleAIAnalysisResult(_ result: Result<String, Error>) {
        // 设置分析后高度为400px
        setHeight(normalHeight)
        
        switch result {
        case .success(let analysis):
            print("✅ AI分析成功，更新内容")
            updateAIContent(analysis)
        case .failure(let error):
            print("❌ AI分析失败: \(error.localizedDescription)")
            showErrorState(error)
        }
    }
    
    // MARK: - 显示加载状态
    private func showLoadingState() {
        // 分析开始时不改变高度，保持默认高度
        
        let loadingContent = """
        # ⚡ 执行中...
        """
        
        updateAIContent(loadingContent)
    }
    
    // MARK: - 更新AI内容
    private func updateAIContent(_ content: String) {
        // 使用现有的渲染方法
        updateContent(content)
    }
    
    // MARK: - 设置高度
    func setHeight(_ height: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新父窗口中的高度约束
            if let parentWindow = self.parentWindow {
                parentWindow.updateAIHeightConstraint(height)
            }
            
            print("📏 AI面板高度设置为: \(height)")
        }
    }
    
    // MARK: - 显示错误状态
    private func showErrorState(_ error: Error) {
        let errorContent = """
        # ❌ \(LocalizationManager.localized("ai_analysis_failed"))
        
        **错误信息：** \(error.localizedDescription)
        
        ---
        
        **可能的原因：**
        - 网络连接问题
        - \(LocalizationManager.localized("service_unavailable"))
        - \(LocalizationManager.localized("request_format_error"))
        
        **建议操作：**
        1. 检查网络连接
        2. 稍后重试
        3. 联系技术支持
        
        ---
        
        *\(LocalizationManager.localized("please_retry_later"))*
        """
        
        updateAIContent(errorContent)
    }
    
    // MARK: - 显示和隐藏
    func show() {
        guard !isVisible else { return }
        
        isVisible = true
        alphaValue = 1.0
        
        // 同步当前选中的AI厂商
        syncCurrentProvider()
        
        // 直接显示，无动画，使用自适应高度
        // frame.size.height = 400.0  // 移除固定高度设置
        
        // 强制配置滚动视图
        DispatchQueue.main.async { [weak self] in
            self?.configureScrollView()
            self?.injectScrollbarJavaScript()
        }
    }
    
    func hide() {
        guard isVisible else { return }
        
        // 清理定时器和缓存
        renderTimer?.invalidate()
        renderTimer = nil
        contentCache.removeAll()
        lastContent = ""
        
        // 清空AI分析缓存，确保下次显示时使用最新提示词
        AIAnalysisService.shared.clearCache()
        //print("🧹 AI面板隐藏时已清空AI分析缓存")
        
        // 重置高度为默认高度80px
        setHeight(defaultHeight)
        
        // 直接隐藏，无动画
        isVisible = false
        alphaValue = 0.0
        frame.size.height = 0
        
    }
    
    // MARK: - 尺寸计算
    func fittingSize() -> NSSize {
        // 固定尺寸：宽度300px，高度根据当前状态决定
        let currentHeight = frame.height > 0 ? frame.height : defaultHeight
        return NSSize(width: 300, height: currentHeight)
    }
}

// MARK: - WKWebView代理
extension AIDetailExplanationPanel: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 阻止外部链接在新窗口中打开
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // 阻止在新窗口中打开链接
        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // WebView加载完成后，确保滚动设置生效
        DispatchQueue.main.async { [weak self] in
            self?.configureScrollView()
            // 注入JavaScript强制显示滚动条
            self?.injectScrollbarJavaScript()
        }
    }
}

// MARK: - 拖动覆盖层视图
class DragOverlayView: NSView {
    weak var parentPanel: AIDetailExplanationPanel?
    
    // 拖拽相关属性
    private var initialLocation: NSPoint = .zero
    private var initialWindowOrigin: NSPoint = .zero
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // 检查点击位置是否在AI厂商选择器或关闭按钮区域内
        if let parentPanel = parentPanel {
            let aiProviderFrame = parentPanel.aiProviderPopUpButton.convert(parentPanel.aiProviderPopUpButton.bounds, to: self)
            let closeButtonFrame = parentPanel.closeButton.convert(parentPanel.closeButton.bounds, to: self)
            
            // 如果点击在AI厂商选择器或关闭按钮区域内，不处理点击事件
            if aiProviderFrame.contains(point) || closeButtonFrame.contains(point) {
                return nil // 让事件传递给下层控件
            }
        }
        
        // 其他区域允许拖拽
        return super.hitTest(point)
    }
    
    override func mouseDown(with event: NSEvent) {
        // 记录初始位置 - 使用屏幕坐标
        initialLocation = NSEvent.mouseLocation
        initialWindowOrigin = self.window?.frame.origin ?? .zero
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = self.window else { return }
        
        // 使用屏幕坐标进行更流畅的拖拽
        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - initialLocation.x
        let deltaY = currentLocation.y - initialLocation.y
        
        let newOrigin = NSPoint(
            x: initialWindowOrigin.x + deltaX,
            y: initialWindowOrigin.y + deltaY
        )
        
        // 直接设置窗口位置，不使用动画上下文
        window.setFrameOrigin(newOrigin)
    }
}
